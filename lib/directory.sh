#!/bin/bash
#===============================================================================
# FICHIER: lib/directory.sh
# DESCRIPTION: CIDST - Gestion des dossiers, permissions et ACL V2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

#-------------------------------
# Chemins
#-------------------------------
get_chemin_groupe() {
    echo "$DOSSIER_BASE/$1"
}

get_chemin_utilisateur() {
    echo "$DOSSIER_BASE/$1/$2"
}

#-------------------------------
# Création
#-------------------------------
creer_dossier_groupe() {
    local groupe="$1"
    local chemin="$DOSSIER_BASE/$groupe"

    mkdir -p "$chemin"
    chmod 770 "$chemin"

    local chef
    chef=$(get_chef_groupe "$groupe")
    local pdg
    pdg=$(get_pdg)

    if [ -n "$chef" ]; then
        chown "$chef:$groupe" "$chemin" 2>/dev/null || true
    elif [ -n "$pdg" ]; then
        chown "$pdg:$groupe" "$chemin" 2>/dev/null || true
    fi

    log_info "Dossier groupe $groupe créé/vérifié"
}

creer_dossier_utilisateur() {
    local nom="$1"
    local groupe="$2"
    local role="$3"

    local dossier_groupe="$DOSSIER_BASE/$groupe"
    local dossier_user="$dossier_groupe/$nom"

    if [ -d "$dossier_user" ]; then
        # Mettre à jour les permissions si le dossier existe
        chown "$nom:$groupe" "$dossier_user" 2>/dev/null || true
        chmod 750 "$dossier_user"
        return 0
    fi

    mkdir -p "$dossier_user"
    chown "$nom:$groupe" "$dossier_user"
    chmod 750 "$dossier_user"

    # Créer fichier surveillance
    local fichier_surveillance="$dossier_user/surveillance.txt"
    touch "$fichier_surveillance"
    chown "$nom:$groupe" "$fichier_surveillance"
    chmod 700 "$fichier_surveillance"

    local chef
    chef=$(get_chef_groupe "$groupe")
    local pdg
    pdg=$(get_pdg)

    # Configurer ACLs selon le rôle
    if commande_existe setfacl; then
        if est_chef "$role"; then
            # Chef: accès complet sur son dossier groupe
            setfacl -m u:"$pdg":r-x "$dossier_user" 2>/dev/null || true
            setfacl -m u:"$pdg":rwx "$dossier_groupe" 2>/dev/null || true
            setfacl -m u:"$chef":rw "$fichier_surveillance" 2>/dev/null || true

        elif est_pdg "$role"; then
            # PDG: propriétaire de tout
            chown "$pdg:$groupe" "$dossier_groupe" 2>/dev/null || true
            setfacl -m u:"$pdg":rwx "$dossier_user" 2>/dev/null || true

        else
            # Employé standard
            setfacl -m u:"$pdg":r-x "$dossier_user" 2>/dev/null || true
            if [ -n "$chef" ]; then
                setfacl -m u:"$chef":rw "$fichier_surveillance" 2>/dev/null || true
            fi
        fi
    fi

    log_info "Dossier utilisateur $nom créé (rôle: ${role:-employe})"
}

#-------------------------------
# Permissions de base
#-------------------------------
set_permissions_base() {
    chmod 770 "$DOSSIER_BASE"
    local pdg
    pdg=$(get_pdg)

    if [ -n "$pdg" ]; then
        chown "$pdg:$GROUPE_ENTREPRISE" "$DOSSIER_BASE" 2>/dev/null || true
    else
        log_info "PDG inexistant, utilisation de root"
        chown root:"$GROUPE_ENTREPRISE" "$DOSSIER_BASE" 2>/dev/null || true
    fi

    # Sticky bit sur le dossier base pour éviter suppressions non autorisées
    chmod +t "$DOSSIER_BASE" 2>/dev/null || true
}

#-------------------------------
# Changement de groupe (archivage ancien dossier)
#-------------------------------
archiver_ancien_dossier() {
    local nom="$1"
    local ancien_groupe="$2"
    local pdg="$3"
    local pdg_groupe="$4"

    local ancien_dossier="$DOSSIER_BASE/$ancien_groupe/$nom"

    if [ ! -d "$ancien_dossier" ]; then
        return 0
    fi

    local nom_archive
    nom_archive="${nom}_ancien_$(get_unix_timestamp)"
    local archive_groupe="$ARCHIVE_DIR/$ancien_groupe"

    mkdir -p "$archive_groupe"

    # Déplacer et compresser
    mv "$ancien_dossier" "$archive_groupe/$nom_archive"

    if [ -n "$pdg" ] && [ -n "$pdg_groupe" ]; then
        chown -R "$pdg:$pdg_groupe" "$archive_groupe/$nom_archive" 2>/dev/null || true
    fi

    chmod 750 "$archive_groupe/$nom_archive"

    log_info "Ancien dossier de $nom archivé: $ancien_groupe/$nom_archive"
}
