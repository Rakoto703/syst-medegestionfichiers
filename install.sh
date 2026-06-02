#!/bin/bash
#===============================================================================
# FICHIER: install.sh
# DESCRIPTION: Script d'installation du système de gestion CIDST V2.0
#===============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/srv/cidst"
LIB_DIR="$INSTALL_DIR/lib"

echo "=== Installation Système de Gestion CIDST V2.0 ==="

# Vérification root
if [ "$EUID" -ne 0 ]; then
    echo "ERREUR: Ce script doit être exécuté en tant que root"
    exit 1
fi

# Installation des dépendances système pour Ubuntu
echo "[0/6] Installation des dépendances système..."
apt update
apt install -y samba samba-common-bin clamav clamav-daemon sqlite3 openssh-server ufw inotify-tools argon2 openssl

# Activer et démarrer Samba si le paquet était déjà installé ou vient d'être installé
if command -v systemctl >/dev/null 2>&1; then
    for service_name in samba smbd nmbd; do
        if systemctl list-unit-files | grep -q "^${service_name}\.service"; then
            systemctl enable --now "${service_name}.service" 2>/dev/null || true
        fi
    done
fi

# Création de la structure
echo "[1/6] Création de la structure..."
mkdir -p "$INSTALL_DIR" "$LIB_DIR" /srv/cidst /srv/cidst/_archive /var/log

# Vérification de la dépendance SQLite (redondant mais sécurisé)
if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "SQLite3 non trouvé - installation automatique sur Ubuntu..."
    apt update && apt install -y sqlite3
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "ERREUR: Impossible d'installer sqlite3"
        exit 1
    fi
    echo "SQLite3 installé avec succès"
fi

# Copie des fichiers
echo "[2/6] Installation des fichiers..."
cp "$REPO_DIR/config.sh" "$INSTALL_DIR/"
cp "$REPO_DIR/main.sh" "$INSTALL_DIR/"
cp "$REPO_DIR/csv_watcher.sh" "$INSTALL_DIR/"
cp "$REPO_DIR/admin_cidst.sh" "$INSTALL_DIR/"
cp "$REPO_DIR/lib/"*.sh "$LIB_DIR/"
# Permissions
echo "[3/6] Configuration des permissions..."
chmod 750 "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR/main.sh"
chmod 700 "$INSTALL_DIR/csv_watcher.sh"
chmod 700 "$INSTALL_DIR/admin_cidst.sh"
chmod 644 "$INSTALL_DIR/config.sh"
chmod 755 "$LIB_DIR"
chmod 644 "$LIB_DIR/"*.sh

# Initialisation de la base SQLite
. "$INSTALL_DIR/config.sh"
. "$LIB_DIR/database.sh"
init_database

# Fichier CSV exemple (OPTIONNEL - pour import legacy uniquement)
if [ ! -f "$INSTALL_DIR/users.csv" ]; then
    cat > "$INSTALL_DIR/users.csv" << 'EOF'
# OPTIONNEL - Fichier CSV hérité pour import de données existantes
# Le système utilise maintenant la base SQLite par défaut
# Format: nom,motdepasse,groupe,role
# Rôles: pdg (Directeur), chef (Chef service/département), employe (Agent)
# Groupes: direction, saf, scrp, stic, dai, dti, drsi, ddi, dvrre, cati, antenne_fianarantsoa, antenne_toamasina, antenne_mahajanga
#
# EXEMPLE (à supprimer après utilisation):
# directeur_cidst,SecureP@ss123!,direction,pdg
# saf_chef,SecureP@ss123!,saf,chef
# admin_saf1,SecureP@ss123!,saf,employe
EOF
    echo "[4/6] Fichier CSV optionnel créé (pour compatibilité legacy)"
else
    echo "[4/6] Fichier CSV existant conservé"
fi

# Service systemd pour le watcher (24/7) - OPTIONNEL
# Ce service n'est activé que si un CSV est présent
cat > /etc/systemd/system/cidst-csv-watcher.service << EOF
[Unit]
Description=Surveillance CSV Gestion CIDST (24/7) [OPTIONNEL]
After=network.target
Wants=network.target
Requires=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/csv_watcher.sh
Restart=always
RestartSec=5
StartLimitInterval=0
StartLimitBurst=0
User=root
Group=root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WorkingDirectory=$INSTALL_DIR
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cidst-watcher

# Sécurité renforcée
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$INSTALL_DIR /srv/cidst /var/log
InaccessiblePaths=/home /root /boot /sys /proc /dev

[Install]
WantedBy=multi-user.target
EOF

# Service de monitoring continu
cat > /etc/systemd/system/cidst-monitoring.service << EOF
[Unit]
Description=Monitoring continu CIDST (24/7)
After=network.target cidst-csv-watcher.service
Wants=cidst-csv-watcher.service

[Service]
Type=simple
ExecStart=$INSTALL_DIR/lib/monitor.sh --continuous
Restart=always
RestartSec=30
User=root
Group=root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WorkingDirectory=$INSTALL_DIR
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cidst-monitor

[Install]
WantedBy=multi-user.target
EOF

# Service de nettoyage automatique
cat > /etc/systemd/system/cidst-cleanup.service << EOF
[Unit]
Description=Nettoyage automatique CIDST (24/7)
After=network.target

[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/lib/cleanup.sh
User=root
Group=root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WorkingDirectory=$INSTALL_DIR
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cidst-cleanup

[Install]
WantedBy=multi-user.target
EOF

# Timer pour nettoyage quotidien
cat > /etc/systemd/system/cidst-cleanup.timer << EOF
[Unit]
Description=Timer nettoyage quotidien CIDST
Requires=cidst-cleanup.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
EOF

# Service antivirus périodique
cat > /etc/systemd/system/cidst-antivirus.service << EOF
[Unit]
Description=Scan antivirus périodique CIDST
After=network.target

[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/lib/antivirus.sh --full-scan
User=root
Group=root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WorkingDirectory=$INSTALL_DIR
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cidst-antivirus
TimeoutSec=3600

[Install]
WantedBy=multi-user.target
EOF

# Timer pour scan antivirus hebdomadaire
cat > /etc/systemd/system/cidst-antivirus.timer << EOF
[Unit]
Description=Timer scan antivirus hebdomadaire CIDST
Requires=cidst-antivirus.service

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
# Activation selective du watcher CSV si le fichier existe
if [ -f "$INSTALL_DIR/users.csv" ] && [ -s "$INSTALL_DIR/users.csv" ]; then
    systemctl enable cidst-csv-watcher.service
    echo "ℹ CSV détecté : cidst-csv-watcher activé"
else
    systemctl disable cidst-csv-watcher.service || true
    echo "✓ CSV absent : système basé 100% SQLite"
fi
systemctl enable cidst-monitoring.service
systemctl enable cidst-cleanup.timer
systemctl enable cidst-antivirus.timer

echo "[5/6] Installation CIDST 24/7 terminée!"
echo ""
echo "Services activés pour fonctionnement 24/7:"
echo "  - cidst-monitoring.service     : Monitoring continu des ressources"
echo "  - cidst-cleanup.timer          : Nettoyage automatique quotidien"
echo "  - cidst-antivirus.timer        : Scan antivirus hebdomadaire"
echo "  - cidst-csv-watcher.service    : [OPTIONNEL] Surveillance CSV si présent"
echo ""
echo "ℹ Gestion des utilisateurs:"
echo "  • Via interface admin :         sudo /srv/cidst/admin_cidst.sh"
echo "  • Via base SQLite :             sqlite3 /srv/cidst/cidst.db"
echo "  • Via CSV legacy [optionnel]:   Mettre à jour /srv/cidst/users.csv"
echo ""
echo "Commandes de gestion:"
echo "  systemctl status cidst-monitoring     # État monitoring"
echo "  systemctl list-timers                 # Voir tous les timers"
echo "  journalctl -u cidst-* -f              # Logs temps réel"
echo "  admin_cidst.sh                        # Interface gestion utilisateurs"
echo ""
echo "Logs: tail -f /var/log/cidst_gestion.log"
echo ""
echo "ℹ Démarrage du système:"
echo "  • Via interface admin :     sudo /srv/cidst/admin_cidst.sh"
echo "  • Via main.sh avec CSV :    sudo /srv/cidst/main.sh (optionnel)"
echo "  • Services auto activés :   systemctl status cidst-monitoring"
