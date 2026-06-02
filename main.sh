#!/bin/bash
#===============================================================================
# FICHIER: main.sh
# DESCRIPTION: Script principal de gestion CIDST V2.0 (24/7)
#===============================================================================

set -euo pipefail

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Charger les dépendances dans l'ordre correct
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/group.sh"
source "$SCRIPT_DIR/lib/user.sh"
source "$SCRIPT_DIR/lib/directory.sh"
source "$SCRIPT_DIR/lib/archive.sh"
source "$SCRIPT_DIR/lib/samba.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"
source "$SCRIPT_DIR/lib/monitor.sh"
source "$SCRIPT_DIR/lib/antivirus.sh"
source "$SCRIPT_DIR/lib/firewall.sh"
source "$SCRIPT_DIR/lib/security.sh"
source "$SCRIPT_DIR/lib/database.sh"

#-------------------------------
# Mode récupération automatique
#-------------------------------
mode_recovery() {
    log_section "MODE RÉCUPÉRATION CIDST"

    log_info "Tentative récupération automatique du système"

    # Vérifier les services critiques
    local services=("smbd" "nmbd" "clamav-daemon")
    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service" 2>/dev/null; then
            log_info "Redémarrage service: $service"
            systemctl restart "$service" 2>/dev/null || log_error "Échec $service"
        fi
    done

    # Vérifier la configuration Samba
    if ! testparm -s >/dev/null 2>&1; then
        log_error "Configuration Samba invalide - régénération"
        configurer_samba_securise
    fi

    # Vérifier les utilisateurs système
    analyser_csv
    creer_utilisateurs_cidst

    log_info "Récupération terminée"
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

#-------------------------------
# Vérifications préliminaires
#-------------------------------
verifier_preconditions() {
    # Vérifier root
    if [ "$EUID" -ne 0 ]; then
        log_error "Ce script doit être exécuté en tant que root"
        return 1
    fi

    # Vérifier la présence de sqlite3
    if ! command -v sqlite3 >/dev/null 2>&1; then
        log_error "sqlite3 est requis pour le fonctionnement du système"
        return 1
    fi

    # Le CSV est optionnel : il sert uniquement d'import legacy
    if [ ! -f "$CSV_FILE" ] || [ ! -s "$CSV_FILE" ]; then
        log_info "CSV absent ou vide : utilisation de la base SQLite uniquement"
    fi

    # Vérifier l'espace disque minimum
    local disk_free
    disk_free=$(df / | awk 'NR==2 {print $4}')
    if [ "$disk_free" -lt 1000000 ] 2>/dev/null; then  # 1GB minimum
        log_error "Espace disque insuffisant (< 1GB)"
        return 1
    fi

    return 0
}

#-------------------------------
# Installation des tâches automatiques 24/7
#-------------------------------
installer_taches_automatiques() {
    log_info "Installation tâches automatiques 24/7"

    # Rotation des logs
    cat > /etc/logrotate.d/cidst << EOF
/var/log/cidst_gestion.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 644 root root
    postrotate
        systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}

/var/log/csv_changes.log {
    weekly
    rotate 12
    compress
    missingok
    create 644 root root
}
EOF

    # Tâche de maintenance hebdomadaire
    cat > /etc/cron.weekly/cidst-maintenance << 'EOF'
#!/bin/bash
# Maintenance hebdomadaire CIDST
/srv/cidst/lib/cleanup.sh
/srv/cidst/lib/antivirus.sh --full-scan
find /srv/cidst/_archive -type f -mtime +90 -delete 2>/dev/null || true
EOF
    chmod +x /etc/cron.weekly/cidst-maintenance

    log_info "Tâches automatiques installées"
}

#-------------------------------
# Fonctions spécifiques CIDST
#-------------------------------
creer_groupes_cidst() {
    log_section "CRÉATION GROUPES CIDST"
    creer_groupe_base
    for groupe in "${GROUPS_CIDST[@]}"; do
        if ! groupe_existe "$groupe"; then
            groupadd "$groupe"
            log_info "Groupe CIDST créé: $groupe"
        fi
    done
}

analyser_csv() {
    log_section "ANALYSE DES UTILISATEURS"
    # Analyse du fichier CSV ou de la base SQLite
    if [ -f "$TMP_USERS" ]; then
        : > "$TMP_USERS"
    fi
    if [ -f "$TMP_GROUPS" ]; then
        : > "$TMP_GROUPS"
    fi

    local ligne_num=0
    while IFS=',' read -r nom motdepasse groupe role; do
        ((ligne_num++))
        # Ignorer les lignes vides et commentaires
        [[ -z "$nom" || "$nom" =~ ^[[:space:]]*# ]] && continue

        # Validation basique
        if [[ ! "$nom" =~ ^[a-zA-Z0-9._-]+$ ]]; then
            log_error "Ligne $ligne_num: nom utilisateur invalide: $nom"
            continue
        fi

        echo "$nom:$motdepasse:$groupe:$role" >> "$TMP_USERS"
        echo "$groupe" >> "$TMP_GROUPS"
    done < <(lire_csv)

    # Statistiques
    local nb_users
    nb_users=$(wc -l < "$TMP_USERS" 2>/dev/null || echo "0")
    log_info "Utilisateurs analysés: $nb_users"
}

creer_utilisateurs_cidst() {
    log_section "CRÉATION UTILISATEURS CIDST"
    creer_utilisateurs_linux
    configurer_samba_users
}

creer_repertoires_cidst() {
    log_section "CRÉATION RÉPERTOIRES CIDST"
    creer_repertoires_base
    configurer_acl_cidst
}

configurer_permissions_cidst() {
    log_section "CONFIGURATION PERMISSIONS CIDST"
    appliquer_permissions_cidst
}

# Point d'entrée
main() {
    # Vérifications initiales
    verifier_root
    acquire_lock
    verifier_csv
    init_config

    local date_debut
    date_debut=$(get_timestamp)
    log_section "DÉBUT EXECUTION - $date_debut"

    # Sécurité système
    log_section "SÉCURITÉ SYSTÈME"
    configurer_firewall
    securiser_permissions
    configurer_limites

    # Antivirus
    installer_clamav
    scan_rapide_critique

    # Créer groupe base entreprise
    creer_groupe_base

    # Analyser CSV pour identifier rôles
    log_section "ANALYSE DES RÔLES"
    analyser_roles

    # Configurer permissions de base
    set_permissions_base

    # Traitement des utilisateurs du CSV
    log_section "TRAITEMENT UTILISATEURS"

    local ligne nom motdepasse groupe role ancien_groupe
    local count=0

    while IFS= read -r ligne; do
        [ -z "$ligne" ] && continue

        IFS=',' read -r nom motdepasse groupe role <<< "$ligne"

        nom=$(nettoyer_champ "$nom")
        motdepasse=$(nettoyer_champ "$motdepasse")
        groupe=$(nettoyer_champ "$groupe")
        role=$(nettoyer_champ "$role")

        # Validation sécurité (Anti-injection)
        if ! valider_nom "$nom"; then
            log_error "Nom invalide: '$nom' - ligne ignorée"
            continue
        fi

        if ! valider_nom "$groupe"; then
            log_error "Groupe invalide: '$groupe' - ligne ignorée"
            continue
        fi

        if ! valider_motdepasse "$motdepasse"; then
            log_error "Mot de passe invalide pour: $nom - ligne ignorée"
            continue
        fi

        # Validation des champs obligatoires
        if [ -z "$nom" ] || [ -z "$groupe" ] || [ -z "$motdepasse" ]; then
            log_error "Champs manquants (nom/groupe/mdp) - ligne ignorée"
            continue
        fi

        log_info "Traitement: $nom (groupe: $groupe, rôle: $role)"

        # Créer groupe si nécessaire
        creer_groupe "$groupe"
        creer_dossier_groupe "$groupe"

        # Vérifier changement de groupe pour utilisateur existant
        if utilisateur_existe "$nom"; then
            ancien_groupe=$(get_groupe_utilisateur "$nom")
            if [ "$ancien_groupe" != "$groupe" ]; then
                log_info "Changement de groupe pour $nom: $ancien_groupe -> $groupe"
                changer_groupe_principal "$nom" "$groupe"
                archiver_ancien_dossier "$nom" "$ancien_groupe" "$(get_pdg)" "$(get_pdg_groupe)"
            fi
            # Mettre à jour le mot de passe même si l'utilisateur existe
            echo "$nom:$motdepasse" | chpasswd
            if commande_existe smbpasswd; then
                (echo "$motdepasse"; echo "$motdepasse") | smbpasswd -s -a "$nom" 2>/dev/null || true
            fi
        else
            # Créer nouvel utilisateur
            creer_utilisateur "$nom" "$motdepasse" "$groupe"
        fi

        # Créer/configurer dossier utilisateur
        creer_dossier_utilisateur "$nom" "$groupe" "$role"

        ((count++)) || true

    done < <(lire_csv)

    log_info "$count utilisateurs traités"

    # Nettoyage des éléments absents du CSV
    nettoyer_utilisateurs
    nettoyer_groupes
    nettoyer_malwares

    # Configuration Samba
    log_section "CONFIGURATION SAMBA"
    configurer_samba_securise

    # Monitoring
    installer_cron_antivirus
    executer_monitoring
    auditer_securite

    # Fin
    local date_fin
    date_fin=$(get_timestamp)
    log_section "FIN EXECUTION - $date_fin"

    log_info "Traitement terminé avec succès. Consultez $LOG_FILE pour les détails."
    echo "✓ Traitement terminé. $count utilisateurs traités."
}

# Exécution
main "$@"
