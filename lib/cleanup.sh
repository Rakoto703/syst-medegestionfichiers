#!/bin/bash
#===============================================================================
# FICHIER: lib/cleanup.sh
# DESCRIPTION: Nettoyage des utilisateurs/groupes orphelins CIDST V2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

# Charger les autres dépendances
source "$SCRIPT_DIR/lib/user.sh"
source "$SCRIPT_DIR/lib/group.sh"
source "$SCRIPT_DIR/lib/archive.sh"

#-------------------------------
# Suppression utilisateurs absents du CSV
#-------------------------------
nettoyer_utilisateurs() {
    log_section "NETTOYAGE UTILISATEURS"

    local user uid user_folder
    local pdg pdg_groupe

    pdg=$(get_pdg)
    pdg_groupe=$(get_pdg_groupe)

    while IFS=: read -r user uid _; do
        # Ignorer les utilisateurs système
        case "$uid" in
            ''|*[!0-9]*) continue ;;
        esac
        [ "$uid" -lt "$MIN_UID" ] && continue

        # Ignorer root et system users
        case "$user" in
            root|sync|shutdown|halt|operator|nobody) continue ;;
        esac

        if grep -qx "$user" "$TMP_USERS" 2>/dev/null; then
            continue
        fi

        user_folder=$(find "$DOSSIER_BASE" -type d -name "$user" 2>/dev/null | head -1)

        if [ -n "$user_folder" ]; then
            log_info "Archivage de l'utilisateur orphelin: $user"
            archiver_utilisateur "$user" "$user_folder"
        fi

        if utilisateur_existe "$user"; then
            supprimer_utilisateur "$user"
            log_info "Utilisateur $user supprimé"
        fi

    done < <(awk -F: '{print $1":"$3}' /etc/passwd)
}

#-------------------------------
# Suppression groupes absents du CSV
#-------------------------------
nettoyer_groupes() {
    log_section "NETTOYAGE GROUPES"

    local grp
    local pdg pdg_groupe

    pdg=$(get_pdg)
    pdg_groupe=$(get_pdg_groupe)

    # Créer liste unique des groupes du CSV
    if [ -f "$TMP_GROUPS" ]; then
        sort -u "$TMP_GROUPS" > "$TMP_DIR/groups_unique.txt"
    else
        touch "$TMP_DIR/groups_unique.txt"
    fi

    while IFS=: read -r grp _; do
        if grep -qx "$grp" "$TMP_DIR/groups_unique.txt" 2>/dev/null; then
            continue
        fi

        # Ne pas supprimer les groupes système
        case "$grp" in
            root|sudo|admin|entreprise|users|wheel|staff|adm) continue ;;
        esac

        # Vérifier si le groupe est utilisé
        local membres
        membres=$(getent group "$grp" | awk -F: '{print $4}')
        if [ -n "$membres" ]; then
            log_info "Groupe $grp a encore des membres, conservation"
            continue
        fi

        local dossier_groupe="$DOSSIER_BASE/$grp"

        if [ -d "$dossier_groupe" ]; then
            archiver_groupe "$grp"
            supprimer_dossier_groupe "$grp"
            supprimer_groupe "$grp"
            log_info "Groupe $grp supprimé et archivé"
        else
            supprimer_groupe "$grp"
            log_info "Groupe $grp supprimé (sans données)"
        fi

    done < /etc/group
}

#-------------------------------
# Nettoyage malwares et fichiers suspects
#-------------------------------
nettoyer_malwares() {
    log_section "NETTOYAGE MALWARES & FICHIERS SUSPECTS"

    local supprimes=0

    # Supprimer exécutables Windows suspects
    while IFS= read -r -d '' fichier; do
        rm -f "$fichier"
        ((supprimes++))
        log_info "Supprimé malware suspect: $fichier"
    done < <(find "$DOSSIER_BASE" -maxdepth 3 -type f \(              -iname "*.exe" -o -iname "*.bat" -o -iname "*.scr" -o              -iname "*.pif" -o -iname "*.com" -o -iname "*.vbs" -o              -iname "*.js" -o -iname "*.jar" -o -iname "*.cmd" \)
             -print0 2>/dev/null)

    # Supprimer fichiers trop volumineux (>100M)
    while IFS= read -r -d '' gros; do
         rm -f "$gros"
         ((supprimes++))
         log_info "Supprimé gros fichier: $gros"
    done < <(find "$DOSSIER_BASE" -type f -size +100M -print0 2>/dev/null)

    # Corriger permissions SUID/SGID dans l'entreprise
    find "$DOSSIER_BASE" -type f \( -perm -4000 -o -perm -2000 \)          -exec chmod u-s,g-s {} \; 2>/dev/null || true

    # Corriger permissions des dossiers
    find "$DOSSIER_BASE" -type d -exec chmod 770 {} \; 2>/dev/null || true
    find "$DOSSIER_BASE" -type f -exec chmod 660 {} \; 2>/dev/null || true

    # Supprimer fichiers cachés suspects (sauf ._.* pour macOS)
    find "$DOSSIER_BASE" -maxdepth 3 -type f -name ".*" ! -name "._*"          -delete 2>/dev/null || true

    log_info "Nettoyage malwares terminé: $supprimes fichiers supprimés"
}
