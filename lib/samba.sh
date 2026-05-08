#!/bin/bash
#===============================================================================
# FICHIER: lib/samba.sh - SAMBA CIDST - VERSION SÉCURISÉE SMB3 + ACL V2.0
#===============================================================================
# Gestion des partages Samba pour services/départements CIDST
# - SAF, SCRP, STIC (Services)
# - DAI, DTI, DRSI, DDI, DVRRE (Départements)
# - CATI, Antennes régionales
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/user.sh"

sauvegarder_config() {
    if [ ! -f "$SAMBA_CONF" ]; then
        log_error "Fichier Samba non trouvé: $SAMBA_CONF"
        return 1
    fi
    local backup="${SAMBA_CONF}.backup_$(get_unix_timestamp)"
    cp "$SAMBA_CONF" "$backup"
    log_info "Configuration Samba CIDST sauvegardée: $backup"
}

nettoyer_partages_auto() {
    if [ -f "$SAMBA_CONF" ]; then
        # Supprimer uniquement notre bloc CIDST
        sed -i '/### CIDST START ###/,/### CIDST END ###/d' "$SAMBA_CONF"
        # Nettoyer les lignes vides multiples
        sed -i '/^$/N;/^\n$/D' "$SAMBA_CONF"
    fi
}

configurer_samba_securise() {
    if [ ! -f "$SAMBA_CONF" ]; then
        log_error "Samba non installé ou configuré"
        return 1
    fi

    sauvegarder_config
    nettoyer_partages_auto

    local pdg
    pdg=$(get_pdg)

    if [ -z "$pdg" ]; then
        log_error "Aucun PDG défini dans le CSV"
        return 1
    fi

    # Configuration globale SMB3 + chiffrement obligatoire
    cat >> "$SAMBA_CONF" << EOF

### CIDST START ###
# Configuration sécurisée SMB3 CIDST - Générée automatiquement
# Partages pour Services/Départements CIDST
# NE PAS MODIFIER MANUELLEMENT
[global]
   min protocol = SMB3_11
   max protocol = SMB3_11
   smb encrypt = required
   smb2 leases = yes
   restrict anonymous = 2
   ntlm auth = ntlmv2-only
   server max protocol = SMB3_11
   hosts allow = 127.0.0.1 192.167.1.0/24 10.0.0.0/8
   hosts deny = 0.0.0.0/0
   interfaces = lo
   bind interfaces only = yes
   log file = /var/log/samba/%m.log
   max log size = 100
   deadtime = 15
   keepalive = 30

[CIDST_Central]
   path = $DOSSIER_BASE
   comment = Partage Central CIDST - Direction
   browseable = yes
   read only = no
   valid users = $pdg
   admin users = $pdg
   hide unreadable = yes

EOF

    # Partages individuels par Service/Département CIDST
    if [ -f "$TMP_GROUPS" ]; then
        local groupes
        mapfile -t groupes < <(sort -u "$TMP_GROUPS" 2>/dev/null)

        for groupe in "${groupes[@]}"; do
            [ -z "$groupe" ] && continue
            [ "$groupe" = "cidst" ] && continue
            [ "$groupe" = "direction" ] && continue

            local chef
            chef=$(get_chef_groupe "$groupe")

            if [ -d "$DOSSIER_BASE/$groupe" ]; then
                # Noms lisibles pour Samba
                local nom_samba=""
                case "$groupe" in
                    saf) nom_samba="SAF - Affaires Admin Financières" ;;
                    scrp) nom_samba="SCRP - Commercial Relations" ;;
                    stic) nom_samba="STIC - Technologies Information" ;;
                    dai) nom_samba="DAI - Acquisitions Information" ;;
                    dti) nom_samba="DTI - Traitement Information" ;;
                    drsi) nom_samba="DRSI - Réseaux Système Info" ;;
                    ddi) nom_samba="DDI - Diffusion Information" ;;
                    dvrre) nom_samba="DVRRE - Valorisation Recherche" ;;
                    cati) nom_samba="CATI - Tech Innovation" ;;
                    antenne_fianarantsoa) nom_samba="Antenne Fianarantsoa" ;;
                    antenne_toamasina) nom_samba="Antenne Toamasina" ;;
                    antenne_mahajanga) nom_samba="Antenne Mahajanga" ;;
                    *) nom_samba="$groupe" ;;
                esac

                cat >> "$SAMBA_CONF" << EOF
[$groupe]
   comment = $nom_samba
   path = $DOSSIER_BASE/$groupe
   browseable = yes
   read only = no
   valid users = @$groupe $chef $pdg
   admin users = $pdg
   create mask = 0660
   directory mask = 0770
   force group = $groupe
   vfs objects = acl_xattr
   inherit acls = yes
   access based share enum = yes
   hide unreadable = yes

EOF
            fi
        done
    fi

    echo "### CIDST END ###" >> "$SAMBA_CONF"

    # Validation syntaxe
    if commande_existe testparm; then
        if testparm -s 2>/dev/null | grep -q "ERROR"; then
            log_error "Erreur syntaxe Samba config"
            return 1
        fi
    fi

    redemarrer_samba
    log_info "Samba CIDST SMB3 sécurisé configuré avec partages Services/Départements"
}

redemarrer_samba() {
    if commande_existe systemctl; then
        systemctl restart smbd nmbd 2>/dev/null || true
        systemctl enable smbd nmbd 2>/dev/null || true
        log_info "Services Samba CIDST redémarrés"
    else
        log_error "systemctl non disponible"
    fi
}
