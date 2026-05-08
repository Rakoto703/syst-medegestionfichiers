#!/bin/bash
#===============================================================================
# FICHIER: lib/group.sh
# DESCRIPTION: CIDST - Gestion des groupes Linux (Services/Départements) V2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

#-------------------------------
# Vérification et création
#-------------------------------
groupe_existe() {
    getent group "$1" > /dev/null 2>&1
}

creer_groupe_base() {
    if ! groupe_existe "$GROUPE_ENTREPRISE"; then
        groupadd "$GROUPE_ENTREPRISE"
        log_info "Groupe $GROUPE_ENTREPRISE créé"
    else
        log_debug "Groupe $GROUPE_ENTREPRISE existe déjà"
    fi
}

creer_groupe() {
    local groupe="$1"

    if [ -z "$groupe" ]; then
        return 1
    fi

    if ! groupe_existe "$groupe"; then
        groupadd "$groupe"
        mkdir -p "$DOSSIER_BASE/$groupe"
        chmod 770 "$DOSSIER_BASE/$groupe"
        log_info "Groupe $groupe créé"
        return 0
    else
        # S'assurer que le dossier existe
        mkdir -p "$DOSSIER_BASE/$groupe"
        chmod 770 "$DOSSIER_BASE/$groupe"
        log_debug "Groupe $groupe existe déjà"
    fi
    return 1
}

#-------------------------------
# Suppression
#-------------------------------
supprimer_groupe() {
    local groupe="$1"

    if groupe_existe "$groupe"; then
        groupdel "$groupe" 2>/dev/null || true
        log_info "Groupe $groupe supprimé"
    fi
}

#-------------------------------
# Récupération du groupe actuel
#-------------------------------
get_groupe_utilisateur() {
    id -gn "$1" 2>/dev/null || echo ""
}

#-------------------------------
# Changement de groupe
#-------------------------------
changer_groupe_principal() {
    local utilisateur="$1"
    local nouveau_groupe="$2"

    if [ -z "$nouveau_groupe" ] || [ -z "$utilisateur" ]; then
        return 1
    fi

    usermod -g "$nouveau_groupe" "$utilisateur" 2>/dev/null || {
        log_error "Impossible de changer le groupe de $utilisateur vers $nouveau_groupe"
        return 1
    }
    log_info "Groupe principal de $utilisateur changé vers $nouveau_groupe"
}
