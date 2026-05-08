#!/bin/bash
#===============================================================================
# FICHIER: csv_watcher.sh
# DESCRIPTION: CIDST - Surveillance temps réel du CSV V2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/antivirus.sh"

#!/bin/bash
#===============================================================================
# FICHIER: csv_watcher.sh
# DESCRIPTION: CIDST - Surveillance temps réel du CSV V2.0 (24/7)
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/antivirus.sh"

#-------------------------------
# Gestion des signaux pour arrêt propre
#-------------------------------
trap 'log_info "Arrêt propre du watcher CSV demandé"; cleanup; exit 0' INT TERM

cleanup() {
    log_info "Nettoyage ressources watcher CSV"
    # Nettoyer les processus enfants si nécessaire
    pkill -P $$ 2>/dev/null || true
}

#-------------------------------
# Vérification robustesse système
#-------------------------------
verifier_systeme() {
    # Vérifier que les services critiques sont actifs
    local services_critiques=("smbd" "nmbd")
    for service in "${services_critiques[@]}"; do
        if ! systemctl is-active --quiet "$service" 2>/dev/null; then
            log_alert "Service critique $service inactif - tentative redémarrage"
            systemctl restart "$service" 2>/dev/null || log_error "Échec redémarrage $service"
        fi
    done

    # Vérifier l'espace disque
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
    if [ "$disk_usage" -gt 95 ] 2>/dev/null; then
        log_alert "Espace disque critique: ${disk_usage}% - Nettoyage d'urgence"
        find /tmp -type f -mtime +1 -delete 2>/dev/null || true
        find /var/log -name "*.log" -size +100M -exec truncate -s 50M {} \; 2>/dev/null || true
    fi
}

# Vérifier que inotifywait est disponible
if ! commande_existe inotifywait; then
    log_info "Installation de inotify-tools..."
    apt-get update >/dev/null 2>&1
    apt-get install -y inotify-tools >/dev/null 2>&1
fi

scan_critique() {
    log_info "Scan antivirus déclenché par modification CSV"
    scan_rapide_critique
}

log_info "Démarrage surveillance CSV 24/7: $CSV_FILE"

# Boucle principale avec récupération automatique
while true; do
    # Vérification périodique du système toutes les 10 minutes
    verifier_systeme &

    # Surveillance des modifications CSV
    if inotifywait -m -e modify,create,delete,move --timeout 600 "$CSV_FILE" 2>/dev/null | while read -r path action file; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] CSV $action: $file" >> /var/log/csv_changes.log

        # Attendre que l'écriture soit terminée (avec timeout)
        local timeout=30
        local count=0
        while [ $count -lt $timeout ] && lsof "$CSV_FILE" >/dev/null 2>&1; do
            sleep 1
            ((count++))
        done

        # Vérifier que le fichier est valide avant exécution
        if [ -f "$CSV_FILE" ] && [ -s "$CSV_FILE" ]; then
            log_info "Modification CSV détectée, exécution main.sh"

            # Exécuter avec timeout pour éviter les blocages
            timeout 300 "$SCRIPT_DIR/main.sh" || {
                log_error "Timeout ou erreur lors de l'exécution main.sh"
                # Tenter une récupération
                sleep 10
                "$SCRIPT_DIR/main.sh" --recovery || log_error "Échec récupération"
            }

            scan_critique
        else
            log_error "Fichier CSV invalide ou vide après modification"
        fi
    done; then
        # inotifywait s'est terminé normalement
        log_info "inotifywait terminé, redémarrage surveillance"
    else
        # Erreur inotifywait, attendre avant redémarrage
        log_error "Erreur inotifywait, redémarrage dans 30 secondes"
        sleep 30
    fi
done
