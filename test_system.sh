#!/bin/bash
#===============================================================================
# FICHIER: test_system.sh
# DESCRIPTION: Tests de validation du système CIDST 24/7
#===============================================================================

set -euo pipefail

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Charger les dépendances
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

#===============================================================================
# TESTS DE VALIDATION SYSTÈME CIDST 24/7
#===============================================================================

main() {
    log_section "TESTS DE VALIDATION SYSTÈME CIDST 24/7"

    if [ "$EUID" -ne 0 ]; then
        log_error "Les tests doivent être exécutés en tant que root"
        exit 1
    fi

    local tests_reussis=0
    local tests_totaux=0

    # Test 1: Structure des fichiers
    ((tests_totaux++))
    if test_structure_fichiers; then
        ((tests_reussis++))
        log_info "✓ Structure des fichiers OK"
    else
        log_error "✗ Structure des fichiers NOK"
    fi

    # Test 2: Services systemd
    ((tests_totaux++))
    if test_services_systemd; then
        ((tests_reussis++))
        log_info "✓ Services systemd OK"
    else
        log_error "✗ Services systemd NOK"
    fi

    # Test 3: Permissions et sécurité
    ((tests_totaux++))
    if test_permissions_securite; then
        ((tests_reussis++))
        log_info "✓ Permissions et sécurité OK"
    else
        log_error "✗ Permissions et sécurité NOK"
    fi

    # Test 4: Configuration Samba
    ((tests_totaux++))
    if test_configuration_samba; then
        ((tests_reussis++))
        log_info "✓ Configuration Samba OK"
    else
        log_error "✗ Configuration Samba NOK"
    fi

    # Test 5: Antivirus
    ((tests_totaux++))
    if test_antivirus; then
        ((tests_reussis++))
        log_info "✓ Antivirus OK"
    else
        log_error "✗ Antivirus NOK"
    fi

    # Test 6: Firewall
    ((tests_totaux++))
    if test_firewall; then
        ((tests_reussis++))
        log_info "✓ Firewall OK"
    else
        log_error "✗ Firewall NOK"
    fi

    # Test 7: Timers systemd
    ((tests_totaux++))
    if test_timers_systemd; then
        ((tests_reussis++))
        log_info "✓ Timers systemd OK"
    else
        log_error "✗ Timers systemd NOK"
    fi

    # Test 8: Fonctionnalités 24/7
    ((tests_totaux++))
    if test_fonctionnalites_24_7; then
        ((tests_reussis++))
        log_info "✓ Fonctionnalités 24/7 OK"
    else
        log_error "✗ Fonctionnalités 24/7 NOK"
    fi

    # Résultats finaux
    log_section "RÉSULTATS DES TESTS"
    log_info "Tests réussis: $tests_reussis/$tests_totaux"

    if [ "$tests_reussis" -eq "$tests_totaux" ]; then
        log_info "🎉 SYSTÈME CIDST 24/7 OPÉRATIONNEL"
        return 0
    else
        log_error "⚠ SYSTÈME CIDST REQUIERT ATTENTION"
        return 1
    fi
}

#-------------------------------
# Test 1: Structure des fichiers
#-------------------------------
test_structure_fichiers() {
    local fichiers_requis=(
        "$DOSSIER_BASE/config.sh"
        "$DOSSIER_BASE/main.sh"
        "$DOSSIER_BASE/recovery.sh"
        "$DOSSIER_BASE/csv_watcher.sh"
        "$DOSSIER_BASE/users.csv"
        "$DOSSIER_BASE/lib/common.sh"
        "$DOSSIER_BASE/lib/user.sh"
        "$DOSSIER_BASE/lib/group.sh"
        "$DOSSIER_BASE/lib/directory.sh"
        "$DOSSIER_BASE/lib/samba.sh"
        "$DOSSIER_BASE/lib/security.sh"
        "$DOSSIER_BASE/lib/firewall.sh"
        "$DOSSIER_BASE/lib/antivirus.sh"
        "$DOSSIER_BASE/lib/monitor.sh"
        "$DOSSIER_BASE/lib/cleanup.sh"
    )

    for fichier in "${fichiers_requis[@]}"; do
        if [ ! -f "$fichier" ]; then
            log_error "Fichier manquant: $fichier"
            return 1
        fi
    done

    # Vérifier que les scripts sont exécutables
    local scripts_exec=(
        "$DOSSIER_BASE/main.sh"
        "$DOSSIER_BASE/recovery.sh"
        "$DOSSIER_BASE/csv_watcher.sh"
    )

    for script in "${scripts_exec[@]}"; do
        if [ ! -x "$script" ]; then
            log_error "Script non exécutable: $script"
            return 1
        fi
    done

    return 0
}

#-------------------------------
# Test 2: Services systemd
#-------------------------------
test_services_systemd() {
    local services=(
        "cidst-csv-watcher.service"
        "cidst-monitoring.service"
        "cidst-cleanup.service"
        "cidst-antivirus.service"
    )

    for service in "${services[@]}"; do
        if ! systemctl is-enabled "$service" 2>/dev/null; then
            log_error "Service non activé: $service"
            return 1
        fi

        if ! systemctl is-active "$service" 2>/dev/null; then
            log_error "Service non actif: $service"
            return 1
        fi
    done

    return 0
}

#-------------------------------
# Test 3: Permissions et sécurité
#-------------------------------
test_permissions_securite() {
    # Vérifier les permissions du répertoire base
    if [ "$(stat -c %a "$DOSSIER_BASE" 2>/dev/null)" != "755" ]; then
        log_error "Permissions incorrectes sur $DOSSIER_BASE"
        return 1
    fi

    # Vérifier le propriétaire
    if [ "$(stat -c %U "$DOSSIER_BASE" 2>/dev/null)" != "root" ]; then
        log_error "Propriétaire incorrect sur $DOSSIER_BASE"
        return 1
    fi

    # Vérifier les limites système
    if [ ! -f /etc/security/limits.d/cidst.conf ]; then
        log_error "Fichier limits manquant"
        return 1
    fi

    return 0
}

#-------------------------------
# Test 4: Configuration Samba
#-------------------------------
test_configuration_samba() {
    # Vérifier que Samba est installé
    if ! command -v smbd >/dev/null 2>&1; then
        log_error "Samba non installé"
        return 1
    fi

    # Vérifier la configuration
    if ! testparm -s >/dev/null 2>&1; then
        log_error "Configuration Samba invalide"
        return 1
    fi

    # Vérifier les services Samba
    if ! systemctl is-active --quiet smbd; then
        log_error "Service smbd non actif"
        return 1
    fi

    if ! systemctl is-active --quiet nmbd; then
        log_error "Service nmbd non actif"
        return 1
    fi

    return 0
}

#-------------------------------
# Test 5: Antivirus
#-------------------------------
test_antivirus() {
    # Vérifier que ClamAV est installé
    if ! command -v clamscan >/dev/null 2>&1; then
        log_error "ClamAV non installé"
        return 1
    fi

    # Vérifier le service
    if ! systemctl is-active --quiet clamav-daemon; then
        log_error "Service clamav-daemon non actif"
        return 1
    fi

    # Vérifier les signatures (au moins 100000 signatures)
    local signatures
    signatures=$(clamscan --version 2>/dev/null | grep -o '[0-9]\+' | head -1 || echo "0")
    if [ "$signatures" -lt 100000 ] 2>/dev/null; then
        log_error "Signatures ClamAV insuffisantes: $signatures"
        return 1
    fi

    return 0
}

#-------------------------------
# Test 6: Firewall
#-------------------------------
test_firewall() {
    # Vérifier que UFW est installé
    if ! command -v ufw >/dev/null 2>&1; then
        log_error "UFW non installé"
        return 1
    fi

    # Vérifier que UFW est actif
    if ! ufw status | grep -q "Status: active"; then
        log_error "UFW non actif"
        return 1
    fi

    return 0
}

#-------------------------------
# Test 7: Timers systemd
#-------------------------------
test_timers_systemd() {
    local timers=(
        "cidst-monitoring.timer"
        "cidst-antivirus.timer"
    )

    for timer in "${timers[@]}"; do
        if ! systemctl is-enabled "$timer" 2>/dev/null; then
            log_error "Timer non activé: $timer"
            return 1
        fi

        if ! systemctl is-active "$timer" 2>/dev/null; then
            log_error "Timer non actif: $timer"
            return 1
        fi
    done

    return 0
}

#-------------------------------
# Test 8: Fonctionnalités 24/7
#-------------------------------
test_fonctionnalites_24_7() {
    # Vérifier le fichier de lock
    if [ -f "$LOCK_FILE" ]; then
        log_error "Fichier de lock présent - système peut-être en cours d'exécution"
        return 1
    fi

    # Vérifier les tâches cron
    if [ ! -f /etc/cron.weekly/cidst-maintenance ]; then
        log_error "Tâche cron hebdomadaire manquante"
        return 1
    fi

    # Vérifier la rotation des logs
    if [ ! -f /etc/logrotate.d/cidst ]; then
        log_error "Configuration logrotate manquante"
        return 1
    fi

    # Tester le mode recovery
    if ! timeout 10 bash "$SCRIPT_DIR/main.sh" --recovery 2>/dev/null; then
        log_error "Mode recovery défaillant"
        return 1
    fi

    return 0
}

# Point d'entrée
main "$@"