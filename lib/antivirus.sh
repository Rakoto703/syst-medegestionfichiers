#!/bin/bash
#===============================================================================
# FICHIER: lib/antivirus.sh - CIDST - CLAMAV V2.0 (24/7)
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

#-------------------------------
# Mode scan complet pour service périodique
#-------------------------------
if [ "$1" = "--full-scan" ]; then
    log_info "Démarrage scan antivirus complet périodique"
    scan_complet_periodique
    exit $?
fi

installer_clamav() {
    if ! dpkg -l | grep -q "^ii.*clamav"; then
        log_info "Installation de ClamAV..."
        apt-get update >/dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y clamav clamav-daemon clamav-freshclam >/dev/null 2>&1

        # Arrêter services pour init propre
        systemctl stop clamav-freshclam clamav-daemon 2>/dev/null || true

        # Initialiser bases
        if ! freshclam --quiet 2>/dev/null; then
            log_error "Échec initialisation bases ClamAV"
            return 1
        fi

        systemctl enable clamav-freshclam clamav-daemon 2>/dev/null || true
        systemctl start clamav-freshclam clamav-daemon 2>/dev/null || true

        log_info "ClamAV installé et services activés"
    else
        verifier_clamav
    fi
}

#-------------------------------
# Scan complet périodique (pour service 24/7)
#-------------------------------
scan_complet_periodique() {
    log_section "SCAN ANTIVIRUS COMPLET PÉRIODIQUE CIDST"

    if ! commande_existe clamscan; then
        log_error "ClamAV non installé - impossible de scanner"
        return 1
    fi

    local debut_scan
    debut_scan=$(date +%s)

    log_info "Début scan complet de $DOSSIER_BASE"

    # Scan avec options optimisées pour serveur 24/7
    local resultat
    resultat=$(clamscan -r --bell -i \
        --exclude-dir="^$ARCHIVE_DIR" \
        --exclude-dir="^/tmp" \
        --exclude-dir="^/var/tmp" \
        --exclude-dir="^/var/log" \
        --max-filesize=50M \
        --max-scansize=100M \
        --max-recursion=15 \
        --follow-dir-symlinks=0 \
        --follow-file-symlinks=0 \
        "$DOSSIER_BASE" 2>&1)

    local fin_scan
    fin_scan=$(date +%s)
    local duree=$((fin_scan - debut_scan))

    # Analyser les résultats
    local infections
    infections=$(echo "$resultat" | grep -c "FOUND" || echo "0")

    if [ "$infections" -gt 0 ]; then
        log_alert "!!! $infections VIRUS DÉTECTÉS lors du scan périodique !!!"
        echo "$resultat" | grep "FOUND" | while read -r line; do
            log_alert "VIRUS: $line"
        done

        # Notification d'urgence (si mail configuré)
        if commande_existe mail; then
            echo "URGENT: $infections virus détectés sur le serveur CIDST

Résultats du scan:
$resultat

Action requise: Vérifier et nettoyer les fichiers infectés.
Serveur: $(hostname)
Date: $(date)

Log complet: $LOG_FILE" | mail -s "ALERTE SÉCURITÉ CIDST - Virus détectés" root
        fi

        return 1
    else
        log_info "Scan périodique terminé - Aucune menace détectée (durée: ${duree}s)"
        return 0
    fi
}

scan_immediat() {
    log_section "SCAN ANTIVIRUS COMPLET"
    if commande_existe clamscan; then
        clamscan -r --bell -i --exclude-dir="^$ARCHIVE_DIR"             --max-filesize=50M --max-scansize=100M             "$DOSSIER_BASE" | tee -a "$LOG_FILE"
    else
        log_error "clamscan non disponible"
    fi
}

scan_rapide_critique() {
    if ! commande_existe clamscan; then
        log_error "ClamAV non installé"
        return 1
    fi

    local resultat
    resultat=$(clamscan --infected --no-summary "$DOSSIER_BASE" 2>/dev/null)

    if [ -n "$resultat" ]; then
        log_alert "!!! VIRUS DÉTECTÉS !!!"
        log_alert "$resultat"
        log_alert "Action requise: exécuter scan_immediat()"
        return 1
    else
        log_info "Scan rapide OK - Aucune menace détectée"
        return 0
    fi
}

installer_cron_antivirus() {
    local cron_file="/etc/cron.d/cidst-antivirus"

    cat > "$cron_file" << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Mise à jour signatures ClamAV toutes les 6h
0 */6 * * * root freshclam --quiet >/var/log/cidst-clamav-update.log 2>&1

# Scan complet quotidien à 3h (silencieux sauf menaces)
0 3 * * * root /srv/cidst/lib/antivirus.sh --full-scan >> /var/log/cidst-antivirus.log 2>&1
EOF
    chmod 644 "$cron_file"
    log_info "Cron ClamAV CIDST installé (sans notification mail)"
}

verifier_clamav() {
    if commande_existe systemctl; then
        if ! systemctl is-active --quiet clamav-daemon 2>/dev/null; then
            log_error "ClamAV daemon inactif → redémarrage automatique"
            systemctl restart clamav-daemon clamav-freshclam 2>/dev/null || log_error "Échec redémarrage ClamAV"
        else
            log_info "ClamAV actif et opérationnel"
        fi
    fi
}
