#!/bin/bash
#===============================================================================
# FICHIER: lib/firewall.sh
# DESCRIPTION: CIDST - UFW sécurisé V2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"

configurer_firewall() {
    if ! commande_existe ufw; then
        log_info "Installation de UFW..."
        apt-get update >/dev/null 2>&1
        apt-get install -y ufw >/dev/null 2>&1
    fi

    # Réinitialiser et configurer
    ufw --force reset >/dev/null 2>&1
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1

    # Services essentiels
    ufw allow ssh comment 'SSH administratif' >/dev/null 2>&1

    # Samba restreint aux réseaux internes
    ufw allow from 192.167.1.0/24 to any app Samba comment 'Samba VLAN interne' >/dev/null 2>&1
    ufw allow from 10.0.0.0/8 to any app Samba comment 'Samba VPN' >/dev/null 2>&1

    # Bloquer explicitement Samba depuis l'extérieur
    ufw deny from any to any app Samba comment 'Blocage externe Samba' >/dev/null 2>&1 || true

    ufw --force enable >/dev/null 2>&1
    log_info "Firewall UFW configuré - Samba limité aux VLANs internes"
}
