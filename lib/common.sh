#!/bin/bash
#===============================================================================
# FICHIER: lib/common.sh
# DESCRIPTION: CIDST - Fonctions utilitaires communes V2.0
#===============================================================================

if [ -n "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

if [ -f "$SCRIPT_DIR/config.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/config.sh"
fi

#-------------------------------
# Validation et vérifications
#-------------------------------
verifier_csv() {
    # Le CSV est maintenant optionnel (fallback sur SQLite)
    if [ -f "$CSV_FILE" ] && [ -s "$CSV_FILE" ]; then
        # Vérifier que le CSV a au moins une ligne de données
        local lignes
        lignes=$(tail -n +2 "$CSV_FILE" | grep -c ',' || true)
        if [ "$lignes" -eq 0 ]; then
            log_warn "CSV existe mais est vide - utilisation DB SQLite"
            return 0
        fi
        log_info "CSV trouvé : $((lignes)) utilisateurs à importer"
        return 0
    fi

    # Vérifier que la base SQLite existe
    if ! [ -f "$DB_FILE" ]; then
        log_error "Tous
 les fichiers manquent : CSV et base SQLite"
        return 1
    fi

    log_info "Base SQLite trouvée : utilisation comme source"
    return 0
}

verifier_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Ce script doit être exécuté en tant que root"
        exit 1
    fi
}

valider_nom() {
    local nom="$1"
    if [ -z "$nom" ]; then
        return 1
    fi
    echo "$nom" | grep -Eq '^[a-zA-Z0-9._-]+$'
}

valider_motdepasse() {
    local mdp="$1"
    if [ ${#mdp} -lt 8 ]; then
        log_error "Mot de passe trop court (min 8 caractères): $mdp"
        return 1
    fi
    return 0
}

#-------------------------------
# Manipulation de texte
#-------------------------------
nettoyer_champ() {
    local champ="$1"
    # Supprimer espaces début/fin, guillemets, et caractères de contrôle
    champ=$(echo "$champ" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')
    echo "$champ"
}

#-------------------------------
# Gestion des dates
#-------------------------------
get_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

get_unix_timestamp() {
    date +%s
}

#-------------------------------
# Lecture CSV robuste ou fallback SQLite
#-------------------------------
lire_csv() {
    if [ -f "$CSV_FILE" ] && [ -s "$CSV_FILE" ]; then
        # Ignorer l'en-tête et les lignes vides
        tail -n +2 "$CSV_FILE" | grep -v '^[[:space:]]*$'
        return
    fi

    # Fallback sur la base SQLite lorsque le CSV n'est pas présent
    sqlite3 -csv "$DB_FILE" "SELECT nom, '' AS motdepasse, groupe, role FROM utilisateurs WHERE actif=1 ORDER BY groupe, nom;"
}

#-------------------------------
# Nettoyage
#-------------------------------
cleanup() {
    log_info "Nettoyage des fichiers temporaires"
    rm -rf "$TMP_DIR"
    release_lock
}

trap cleanup EXIT INT TERM

#-------------------------------
# Vérification commandes
#-------------------------------
commande_existe() {
    command -v "$1" >/dev/null 2>&1
}
