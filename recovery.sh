#!/bin/bash
#===============================================================================
# FICHIER: recovery.sh
# DESCRIPTION: Script de récupération automatique CIDST 24/7
#===============================================================================

set -euo pipefail

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Charger les dépendances
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

#===============================================================================
# SCRIPT DE RÉCUPÉRATION AUTOMATIQUE CIDST 24/7
#===============================================================================

main() {
    log_section "RÉCUPÉRATION AUTOMATIQUE CIDST 24/7"

    # Vérifier si on est root
    if [ "$EUID" -ne 0 ]; then
        log_error "Le script de récupération doit être exécuté en tant que root"
        exit 1
    fi

    # Acquérir le lock de récupération
    if ! acquire_lock_with_timeout 60; then
        log_error "Impossible d'acquérir le lock de récupération"
        exit 1
    fi

    trap 'release_lock; log_error "Récupération interrompue"' INT TERM EXIT

    # Étape 1: Vérification des services critiques
    verifier_services_critiques

    # Étape 2: Vérification de l'intégrité des fichiers
    verifier_integrite_fichiers

    # Étape 3: Récupération des utilisateurs et groupes
    recuperer_utilisateurs_groupes

    # Étape 4: Récupération des partages Samba
    recuperer_samba

    # Étape 5: Nettoyage et optimisation
    nettoyer_systeme

    # Étape 6: Vérification finale
    verification_finale

    log_info "Récupération automatique terminée avec succès"

    release_lock
    trap - INT TERM EXIT
}

#-------------------------------
# Vérification des services critiques
#-------------------------------
verifier_services_critiques() {
    log_info "Vérification des services critiques"

    local services=("smbd" "nmbd" "clamav-daemon" "rsyslog" "cron")
    local service_redemarre=0

    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service" 2>/dev/null; then
            log_info "Redémarrage service critique: $service"
            if systemctl restart "$service" 2>/dev/null; then
                log_info "Service $service redémarré avec succès"
                ((service_redemarre++))
            else
                log_error "Échec redémarrage $service"
            fi
        fi
    done

    log_info "$service_redemarre services critiques vérifiés/redémarrés"
}

#-------------------------------
# Vérification de l'intégrité des fichiers
#-------------------------------
verifier_integrite_fichiers() {
    log_info "Vérification intégrité des fichiers système"

    # Vérifier la configuration Samba
    if ! testparm -s >/dev/null 2>&1; then
        log_error "Configuration Samba corrompue - régénération"
        "$SCRIPT_DIR/lib/samba.sh"
    fi

    # Vérifier les permissions des répertoires
    if [ -d "$DOSSIER_BASE" ]; then
        chown -R root:root "$DOSSIER_BASE" 2>/dev/null || true
        find "$DOSSIER_BASE" -type d -exec chmod 755 {} \; 2>/dev/null || true
    fi

    # Vérifier les logs
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
    fi

    log_info "Intégrité des fichiers vérifiée"
}

#-------------------------------
# Récupération des utilisateurs et groupes
#-------------------------------
recuperer_utilisateurs_groupes() {
    log_info "Récupération utilisateurs et groupes"

    # Recharger le CSV si modifié récemment
    if [ -f "$CSV_FILE" ] && [ -s "$CSV_FILE" ]; then
        log_info "Rechargement configuration utilisateurs depuis CSV"
        "$SCRIPT_DIR/main.sh" --recovery
    else
        log_error "CSV manquant ou vide - récupération impossible"
    fi
}

#-------------------------------
# Récupération des partages Samba
#-------------------------------
recuperer_samba() {
    log_info "Récupération configuration Samba"

    # Recharger la configuration Samba
    if systemctl is-active --quiet smbd; then
        smbcontrol all reload-config 2>/dev/null || true
        log_info "Configuration Samba rechargée"
    fi
}

#-------------------------------
# Nettoyage et optimisation
#-------------------------------
nettoyer_systeme() {
    log_info "Nettoyage et optimisation système"

    # Nettoyer les fichiers temporaires
    find /tmp -name "cidst_*" -type f -mtime +1 -delete 2>/dev/null || true

    # Vérifier l'espace disque
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ] 2>/dev/null; then
        log_warn "Espace disque critique ($disk_usage%) - nettoyage d'urgence"
        "$SCRIPT_DIR/lib/cleanup.sh" --emergency
    fi

    # Optimiser les logs
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo "0") -gt 10000000 ]; then
        log_info "Rotation du fichier de log principal"
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
    fi
}

#-------------------------------
# Vérification finale
#-------------------------------
verification_finale() {
    log_info "Vérification finale du système"

    # Tester les services critiques
    local test_ok=0
    local test_total=0

    # Test Samba
    ((test_total++))
    if systemctl is-active --quiet smbd && systemctl is-active --quiet nmbd; then
        ((test_ok++))
        log_info "✓ Services Samba opérationnels"
    else
        log_error "✗ Services Samba défaillants"
    fi

    # Test ClamAV
    ((test_total++))
    if systemctl is-active --quiet clamav-daemon; then
        ((test_ok++))
        log_info "✓ Service antivirus opérationnel"
    else
        log_error "✗ Service antivirus défaillant"
    fi

    # Test accès répertoires
    ((test_total++))
    if [ -d "$DOSSIER_BASE" ] && [ -r "$DOSSIER_BASE" ]; then
        ((test_ok++))
        log_info "✓ Répertoires CIDST accessibles"
    else
        log_error "✗ Répertoires CIDST inaccessibles"
    fi

    log_info "Tests finaux: $test_ok/$test_total réussis"

    if [ "$test_ok" -eq "$test_total" ]; then
        log_info "✓ Système CIDST récupéré avec succès"
    else
        log_error "⚠ Récupération partielle - vérification manuelle recommandée"
    fi
}

#-------------------------------
# Acquisition du lock avec timeout
#-------------------------------
acquire_lock_with_timeout() {
    local timeout="${1:-30}"
    local count=0

    while [ $count -lt $timeout ]; do
        if acquire_lock 2>/dev/null; then
            return 0
        fi
        sleep 1
        ((count++))
    done

    return 1
}

# Point d'entrée
main "$@"