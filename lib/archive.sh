#!/bin/bash
#===============================================================================
# FICHIER: lib/archive.sh
# DESCRIPTION: CIDST - Gestion des archives de suppression V2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

#-------------------------------
# Archivage utilisateur
#-------------------------------
archiver_utilisateur() {
    local utilisateur="$1"
    local dossier="$2"

    if [ ! -d "$dossier" ]; then
        log_error "Dossier à archiver introuvable: $dossier"
        return 1
    fi

    local groupe
    groupe=$(basename "$(dirname "$dossier")")

    local nom_archive="${utilisateur}_supprime_$(get_unix_timestamp).tar.gz"
    local archive_groupe="$ARCHIVE_DIR/$groupe"

    mkdir -p "$archive_groupe"

    cd "$(dirname "$dossier")" || return 1
    if tar -czf "$archive_groupe/$nom_archive" "$(basename "$dossier")" 2>/dev/null; then
        local pdg
        pdg=$(get_pdg)
        local pdg_groupe
        pdg_groupe=$(get_pdg_groupe)

        if [ -n "$pdg" ] && [ -n "$pdg_groupe" ]; then
            chown "$pdg:$pdg_groupe" "$archive_groupe" 2>/dev/null || true
            chown "$pdg:$pdg_groupe" "$archive_groupe/$nom_archive" 2>/dev/null || true
        fi
        chmod 750 "$archive_groupe/$nom_archive"

        # Supprimer l'original après archivage réussi
        rm -rf "$dossier"

        log_info "Utilisateur $utilisateur archivé dans $groupe/$nom_archive"
        return 0
    else
        log_error "Échec archivage de $utilisateur"
        return 1
    fi
}

#-------------------------------
# Archivage groupe
#-------------------------------
archiver_groupe() {
    local groupe="$1"
    local dossier_groupe="$DOSSIER_BASE/$groupe"

    if [ ! -d "$dossier_groupe" ]; then
        log_error "Dossier groupe à archiver introuvable: $dossier_groupe"
        return 1
    fi

    local nom_archive="${groupe}_supprime_$(get_unix_timestamp).tar.gz"

    cd "$dossier_groupe" || return 1
    if tar -czf "$ARCHIVE_DIR/$nom_archive" ./* 2>/dev/null; then
        local pdg
        pdg=$(get_pdg)
        local pdg_groupe
        pdg_groupe=$(get_pdg_groupe)

        if [ -n "$pdg" ] && [ -n "$pdg_groupe" ]; then
            chown "$pdg:$pdg_groupe" "$ARCHIVE_DIR/$nom_archive" 2>/dev/null || true
        fi
        chmod 750 "$ARCHIVE_DIR/$nom_archive"

        log_info "Groupe $groupe archivé dans $nom_archive"
        return 0
    else
        log_error "Échec archivage du groupe $groupe"
        return 1
    fi
}

#-------------------------------
# Suppression dossier
#-------------------------------
supprimer_dossier_groupe() {
    local groupe="$1"
    if [ -d "$DOSSIER_BASE/$groupe" ]; then
        rm -rf "$DOSSIER_BASE/$groupe"
        log_info "Dossier groupe $groupe supprimé"
    fi
}
