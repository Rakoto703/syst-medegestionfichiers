#!/bin/bash
#===============================================================================
# FICHIER: lib/security.sh - CIDST - Mesures de sécurité renforcées V2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

#-------------------------------  
# Sécurisation des permissions CIDST
#-------------------------------
securiser_permissions() {
    log_section "SÉCURISATION DES PERMISSIONS CIDST"

    # Sticky bit sur les dossiers utilisateurs
    find "$DOSSIER_BASE" -type d -exec chmod +t {} \; 2>/dev/null || true

    # Permissions restrictives sur les archives
    chmod 750 "$ARCHIVE_DIR" 2>/dev/null || true
    chown root:"$GROUPE_ENTREPRISE" "$ARCHIVE_DIR" 2>/dev/null || true

    # Désactiver l'exécution dans les dossiers utilisateurs (si possible)
    log_info "Note: Ajoutez 'noexec,nodev,nosuid' aux options de montage de $DOSSIER_BASE dans /etc/fstab"
}

#-------------------------------  
# Limites de ressources CIDST (anti-DoS)
#-------------------------------
configurer_limites() {
    local limits_file="/etc/security/limits.d/cidst.conf"

    cat > "$limits_file" << EOF
# Limites pour les utilisateurs CIDST (Services/Départements)
@$GROUPE_ENTREPRISE soft nproc 100
@$GROUPE_ENTREPRISE hard nproc 200
@$GROUPE_ENTREPRISE soft nofile 4096
@$GROUPE_ENTREPRISE hard nofile 8192
@$GROUPE_ENTREPRISE soft fsize 104857600
@$GROUPE_ENTREPRISE hard fsize 209715200
@$GROUPE_ENTREPRISE soft cpu 300
@$GROUPE_ENTREPRISE hard cpu 600
EOF

    chmod 644 "$limits_file"
    log_info "Limites de ressources configurées (anti-DoS)"
}

#-------------------------------  
# Audit de sécurité
#-------------------------------
auditer_securite() {
    log_section "AUDIT DE SÉCURITÉ"

    local alertes=0

    # Vérifier les fichiers SUID/SGID suspects
    find "$DOSSIER_BASE" -type f \( -perm -4000 -o -perm -2000 \) > "$TMP_DIR/suid_files.txt" 2>/dev/null

    if [ -s "$TMP_DIR/suid_files.txt" ]; then
        log_alert "Fichiers SUID/SGID trouvés dans l'entreprise:"
        while read -r ligne; do
            log_alert "  $ligne"
            ((alertes++))
        done < "$TMP_DIR/suid_files.txt"
    fi

    # Vérifier les fichiers sans propriétaire
    find "$DOSSIER_BASE" \( -nouser -o -nogroup \) > "$TMP_DIR/orphan_files.txt" 2>/dev/null

    if [ -s "$TMP_DIR/orphan_files.txt" ]; then
        log_alert "Fichiers sans propriétaire trouvés - correction automatique"
        while read -r fichier; do
            chown root:"$GROUPE_ENTREPRISE" "$fichier" 2>/dev/null || true
            ((alertes++))
        done < "$TMP_DIR/orphan_files.txt"
    fi

    # Vérifier les permissions trop ouvertes
    find "$DOSSIER_BASE" -type f -perm /o+w > "$TMP_DIR/world_writable.txt" 2>/dev/null
    if [ -s "$TMP_DIR/world_writable.txt" ]; then
        log_alert "Fichiers world-writable trouvés - correction"
        while read -r fichier; do
            chmod o-w "$fichier" 2>/dev/null || true
            ((alertes++))
        done < "$TMP_DIR/world_writable.txt"
    fi

    if [ "$alertes" -eq 0 ]; then
        log_info "Audit de sécurité: aucun problème détecté"
    else
        log_alert "Audit de sécurité: $alertes problèmes corrigés"
    fi
}
