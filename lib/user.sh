#!/bin/bash
#===============================================================================
# FICHIER: lib/user.sh
# DESCRIPTION: CIDST - Gestion des utilisateurs Linux et Samba V2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

#-------------------------------
# Tableaux associatifs globaux
#-------------------------------
declare -A CHEFS_GROUPE

#-------------------------------
# Vérification
#-------------------------------
utilisateur_existe() {
    id "$1" > /dev/null 2>&1
}

#-------------------------------
# Création
#-------------------------------
creer_utilisateur() {
    local nom="$1"
    local motdepasse="$2"
    local groupe="$3"

    if [ -z "$nom" ] || [ -z "$motdepasse" ] || [ -z "$groupe" ]; then
        log_error "Paramètres manquants pour creer_utilisateur"
        return 1
    fi

    if utilisateur_existe "$nom"; then
        log_debug "Utilisateur $nom existe déjà"
        return 1
    fi

    # Vérifier que le groupe existe
    if ! getent group "$groupe" > /dev/null 2>&1; then
        log_error "Groupe $groupe n'existe pas"
        return 1
    fi

    # Création Linux
    useradd -m -g "$groupe" -G "$GROUPE_ENTREPRISE" "$nom" 2>/dev/null || {
        log_error "Échec création utilisateur Linux: $nom"
        return 1
    }

    # Définir mot de passe Linux
    echo "$nom:$motdepasse" | chpasswd

    # Ajouter à Samba
    if commande_existe smbpasswd; then
        (echo "$motdepasse"; echo "$motdepasse") | smbpasswd -s -a "$nom" 2>/dev/null || {
            log_error "Échec ajout Samba pour: $nom"
        }
        smbpasswd -e "$nom" > /dev/null 2>&1
    fi

    log_info "Utilisateur $nom créé (groupe: $groupe)"
    return 0
}

#-------------------------------
# Suppression
#-------------------------------
supprimer_utilisateur() {
    local nom="$1"

    if ! utilisateur_existe "$nom"; then
        return 0
    fi

    # Supprimer de Samba
    if commande_existe smbpasswd; then
        smbpasswd -x "$nom" 2>/dev/null || true
    fi

    # Supprimer utilisateur Linux et son home
    userdel -r "$nom" 2>/dev/null || {
        # Si home existe encore, le supprimer manuellement
        rm -rf "/home/$nom" 2>/dev/null || true
    }

    log_info "Utilisateur $nom supprimé"
}

#-------------------------------
# Gestion des rôles
#-------------------------------
est_chef() {
    [ "$1" = "chef" ]
}

est_pdg() {
    [ "$1" = "pdg" ]
}

#-------------------------------
# Lecture CSV avec rôles
#-------------------------------
analyser_roles() {
    local ligne nom groupe role motdepasse

    # Réinitialiser les variables globales
    PDG_NOM=""
    PDG_GROUPE=""
    CHEFS_GROUPE=()

    while IFS= read -r ligne; do
        [ -z "$ligne" ] && continue

        IFS=',' read -r nom motdepasse groupe role <<< "$ligne"
        nom=$(nettoyer_champ "$nom")
        groupe=$(nettoyer_champ "$groupe")
        role=$(nettoyer_champ "$role")

        [ -z "$nom" ] && continue
        [ -z "$groupe" ] && continue

        if est_chef "$role"; then
            CHEFS_GROUPE["$groupe"]="$nom"
            log_info "Chef identifié: $nom (groupe: $groupe)"
        fi

        if est_pdg "$role"; then
            PDG_NOM="$nom"
            PDG_GROUPE="$groupe"
            CHEFS_GROUPE["$groupe"]="$nom"
            log_info "PDG identifié: $nom (groupe: $groupe)"
        fi

        echo "$nom" >> "$TMP_USERS"
        echo "$groupe" >> "$TMP_GROUPS"

    done < <(lire_csv)

    # Définir propriétaire archive
    if [ -n "$PDG_NOM" ]; then
        chown -R "$PDG_NOM:$PDG_GROUPE" "$ARCHIVE_DIR" 2>/dev/null || true
        chmod 770 "$ARCHIVE_DIR"
    else
        log_alert "AUCUN PDG DÉFINI - Utilisation de root pour les archives"
        chown root:root "$ARCHIVE_DIR" 2>/dev/null || true
        chmod 750 "$ARCHIVE_DIR"
    fi
}

get_chef_groupe() {
    echo "${CHEFS_GROUPE[$1]:-}"
}

get_pdg() {
    echo "${PDG_NOM:-}"
}

get_pdg_groupe() {
    echo "${PDG_GROUPE:-}"
}
