#!/bin/bash
#===============================================================================
# FICHIER: uninstall.sh
# DESCRIPTION: Script de désinstallation du système de gestion CIDST V2.0
#===============================================================================

set -euo pipefail

INSTALL_DIR="/srv/cidst"
SERVICE_FILES=(
  "/etc/systemd/system/cidst-csv-watcher.service"
  "/etc/systemd/system/cidst-monitoring.service"
  "/etc/systemd/system/cidst-cleanup.service"
  "/etc/systemd/system/cidst-cleanup.timer"
  "/etc/systemd/system/cidst-antivirus.service"
  "/etc/systemd/system/cidst-antivirus.timer"
)
LOG_FILE="/var/log/cidst_gestion.log"

usage() {
    cat << 'EOF'
Usage: sudo ./uninstall.sh [--yes] [--keep-data]

Options:
  --yes         Exécute la désinstallation sans confirmation interactive
  --keep-data   Désactive les services mais conserve les fichiers dans /srv/cidst
  --help        Affiche cette aide
EOF
}

if [ "$EUID" -ne 0 ]; then
    echo "ERREUR: Ce script doit être exécuté en tant que root"
    exit 1
fi

KEEP_DATA=false
AUTO_CONFIRM=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --yes)
            AUTO_CONFIRM=true
            shift
            ;;
        --keep-data)
            KEEP_DATA=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            usage
            exit 1
            ;;
    esac
done

if [ "$AUTO_CONFIRM" = false ]; then
    echo "Attention: cette opération va désinstaller CIDST V2.0."
    if [ "$KEEP_DATA" = true ]; then
        echo "Les services et unités systemd seront supprimés, mais les fichiers de /srv/cidst seront conservés."
    else
        echo "Les fichiers de /srv/cidst et les journaux associés seront supprimés."
    fi
    read -rp "Confirmez-vous la désinstallation ? [o/N] " answer
    case "${answer,,}" in
        o|oui|y|yes)
            ;;
        *)
            echo "Annulation de la désinstallation. Aucune modification n'a été apportée."
            exit 0
            ;;
    esac
fi

echo "=== Désinstallation CIDST V2.0 ==="

echo "Arrêt des services CIDST..."
for service in cidst-csv-watcher.service cidst-monitoring.service cidst-cleanup.service cidst-cleanup.timer cidst-antivirus.service cidst-antivirus.timer; do
    if systemctl list-unit-files | grep -q "^${service}"; then
        systemctl stop "$service" 2>/dev/null || true
        systemctl disable "$service" 2>/dev/null || true
    fi
done

if systemctl daemon-reload >/dev/null 2>&1; then
    echo "systemd rechargé"
fi

for file in "${SERVICE_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "Supprimé: $file"
    fi
done

if [ "$KEEP_DATA" = false ]; then
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo "Supprimé: $INSTALL_DIR"
    else
        echo "Aucun répertoire d'installation trouvé dans $INSTALL_DIR"
    fi
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
        echo "Supprimé: $LOG_FILE"
    fi
else
    echo "Conservation des données dans $INSTALL_DIR"
fi

systemctl daemon-reload >/dev/null 2>&1 || true

echo "=== Désinstallation terminée ==="
if [ "$KEEP_DATA" = false ]; then
    echo "CIDST a été complètement supprimé du système."
else
    echo "CIDST a été désactivé, mais les fichiers de données sont conservés."
fi
