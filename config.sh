#!/bin/bash
#===============================================================================
# FICHIER: config.sh
# DESCRIPTION: Configuration centralisée CIDST V2.0
# ORGANISME: Centre d'Information et de Documentation Scientifique et Technique
#===============================================================================

#-------------------------------
# Chemins principaux (CIDST)
#-------------------------------
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOSSIER_BASE="/srv/cidst"
export DB_FILE="${DOSSIER_BASE}/cidst.db"
#export CSV_FILE="${SCRIPT_DIR}/users.csv"
export LOG_FILE="/var/log/cidst_gestion.log"
export ARCHIVE_DIR="${DOSSIER_BASE}/_archive"
export SAMBA_CONF="/etc/samba/smb.conf"

#-------------------------------
# Fichiers temporaires
#-------------------------------
export TMP_DIR="/tmp/cidst_gestion_$$"
export TMP_USERS="$TMP_DIR/user_list.txt"
export TMP_GROUPS="$TMP_DIR/group_list.txt"
export LOCK_FILE="/var/lock/cidst_gestion.lock"

#-------------------------------
# Paramètres système CIDST
#-------------------------------
export GROUPE_ENTREPRISE="cidst"
export MIN_UID=1000

#-------------------------------
# Variables globales pour Directeur
#-------------------------------
export PDG_NOM=""
export PDG_GROUPE=""

#-------------------------------
# Groupes/Services CIDST
#-------------------------------
export GROUPS_CIDST=(
    "direction"
    "saf"          # Service Affaires Administratives et Financières
    "scrp"         # Service Commercial et Relations Publiques
    "stic"         # Service Technologies de l'Information et Communication
    "dai"          # Département Acquisitions de l'Information
    "dti"          # Département Traitement de l'Information
    "drsi"         # Département Réseaux et Système d'Information
    "ddi"          # Département Diffusion de l'Information
    "dvrre"        # Département Valorisation Résultats Recherche et Edition
    "cati"         # Centre d'Appui à la Technologie et à l'Innovation
    "antenne_fianarantsoa"
    "antenne_toamasina"
    "antenne_mahajanga"
)

#-------------------------------
# Seuils de monitoring (%)
#-------------------------------
export SEUIL_CPU=80
export SEUIL_RAM=80
export SEUIL_DISQUE=80

#-------------------------------
# Fonction d'initialisation
#-------------------------------
init_config() {
    mkdir -p "$TMP_DIR" "$ARCHIVE_DIR" "$DOSSIER_BASE"
    : > "$TMP_USERS"
    : > "$TMP_GROUPS"
}

#-------------------------------
# Fonction de logging
#-------------------------------
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_section() {
    local title="$1"
    log "INFO" "=========================================="
    log "INFO" "== $title =="
    log "INFO" "=========================================="
}

log_error() { log "ERREUR" "$1"; }
log_info() { log "INFO" "$1"; }
log_alert() { log "ALERTE" "$1"; }
log_debug() { log "DEBUG" "$1"; }

#-------------------------------
# Gestion du lock
#-------------------------------
acquire_lock() {
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        echo "ERREUR: Une instance est déjà en cours d'exécution"
        exit 1
    fi
    echo $$ >&200
}

release_lock() {
    flock -u 200 2>/dev/null || true
    rm -f "$LOCK_FILE"
}
