#!/bin/bash
#===============================================================================
# FICHIER: lib/monitor.sh
# DESCRIPTION: CIDST - Monitoring des ressources système V2.0 (24/7)
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
if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/lib/common.sh"
fi

# Note: le mode continu est lancé après la déclaration des fonctions
# (voir la section finale du fichier) afin d'éviter d'appeler des
# fonctions avant qu'elles ne soient définies.

#-------------------------------
# Collecte métriques corrigée
#-------------------------------
get_cpu_usage_sample() {
    local user nice system idle iowait irq softirq steal guest guest_nice
    if ! read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat; then
        echo "0 0"
        return
    fi

    local total=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
    echo "$idle $total"
}

get_cpu_usage() {
    local sum=0
    local i usage idle1 total1 idle2 total2 diff_idle diff_total

    for i in 1 2 3; do
        read -r idle1 total1 < <(get_cpu_usage_sample)
        sleep 0.2
        read -r idle2 total2 < <(get_cpu_usage_sample)

        diff_idle=$((idle2 - idle1))
        diff_total=$((total2 - total1))

        if [ "$diff_total" -le 0 ]; then
            usage=0
        else
            usage=$(( (100 * (diff_total - diff_idle) + diff_total / 2) / diff_total ))
            if [ "$usage" -gt 100 ]; then
                usage=100
            elif [ "$usage" -lt 0 ]; then
                usage=0
            fi
        fi

        sum=$((sum + usage))
    done

    echo $((sum / 3))
}

get_ram_usage() {
    local total used
    total=$(free | awk '/Mem:/ {print $2}')
    used=$(free | awk '/Mem:/ {print $3}')
    if [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
        echo $((used * 100 / total))
    else
        echo "0"
    fi
}

get_disk_usage() {
    if df "$DOSSIER_BASE" >/dev/null 2>&1; then
        df "$DOSSIER_BASE" | awk 'NR==2 {gsub("%",""); print $5}'
    else
        # Si le dossier n'existe pas encore, vérifier /
        df / | awk 'NR==2 {gsub("%",""); print $5}'
    fi
}

#-------------------------------
# Vérification services critiques
#-------------------------------
verifier_services_critiques() {
    local services=("smbd" "nmbd" "sshd" "cron" "rsyslog")
    local service_down=""

    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service" 2>/dev/null; then
            service_down="$service_down $service"
        fi
    done

    if [ -n "$service_down" ]; then
        log_alert "Services arrêtés détectés:$service_down"

        # Tentative de redémarrage automatique
        for service in $service_down; do
            log_info "Tentative redémarrage automatique: $service"
            systemctl restart "$service" 2>/dev/null || log_error "Échec redémarrage $service"
        done
    fi
}

#-------------------------------
# Vérification seuils
#-------------------------------
verifier_seuil() {
    local valeur="$1"
    local seuil="$2"
    local label="$3"

    # Vérifier que ce sont des nombres valides
    case "$valeur" in
        ''|*[!0-9]*) return 0 ;;
    esac

    if [ "$valeur" -gt "$seuil" ]; then
        log_alert "$label élevé: ${valeur}% (seuil: ${seuil}%)"

        # Actions correctives pour seuils critiques
        if [ "$valeur" -ge 95 ] || [ "$valeur" -gt $((seuil + 15)) ]; then
            log_alert "SEUIL CRITIQUE - Actions d'urgence déclenchées"
            actions_urgence "$label"
        fi

        return 1
    fi
    return 0
}

#-------------------------------
# Actions d'urgence pour seuils critiques
#-------------------------------
actions_urgence() {
    local type="$1"

    case "$type" in
        "CPU")
            log_info "Action urgence CPU: Identification processus gourmands"
            ps aux --sort=-%cpu | head -10 | while read -r line; do
                log_info "Processus CPU: $line"
            done
            ;;
        "RAM")
            log_info "Action urgence RAM: Vérification mémoire"
            free -h | while read -r line; do
                log_info "Mémoire: $line"
            done
            ;;
        "Disque")
            log_info "Action urgence Disque: Nettoyage archives temporaires"
            find /tmp -type f -mtime +7 -delete 2>/dev/null || true
            ;;
    esac
}

#-------------------------------
# Monitoring complet
#-------------------------------
executer_monitoring() {
    log_section "MONITORING SYSTÈME CIDST 24/7"

    local cpu ram disk
    cpu=$(get_cpu_usage)
    ram=$(get_ram_usage)
    disk=$(get_disk_usage)

    log_info "CPU: ${cpu}% | RAM: ${ram}% | DISQUE: ${disk}%"

    local status=0
    verifier_seuil "$cpu" "$SEUIL_CPU" "CPU" || status=1
    verifier_seuil "$ram" "$SEUIL_RAM" "RAM" || status=1
    verifier_seuil "$disk" "$SEUIL_DISQUE" "Disque" || status=1

    return $status
}

#-------------------------------
# Mode continu pour service 24/7
#-------------------------------
if [ "$1" = "--continuous" ]; then
    log_info "Démarrage monitoring continu 24/7"

    # Boucle infinie avec gestion des signaux
    trap 'log_info "Arrêt du monitoring continu demandé"; exit 0' INT TERM

    while true; do
        executer_monitoring

        # Vérifier l'état des services critiques
        verifier_services_critiques

        # Pause de 5 minutes entre les vérifications
        sleep 300
    done
fi
