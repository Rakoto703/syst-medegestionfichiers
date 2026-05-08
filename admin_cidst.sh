#!/bin/bash
#===============================================================================
# FICHIER: admin_cidst.sh
# DESCRIPTION: Interface d'administration CIDST V3.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/database.sh"
source "$SCRIPT_DIR/lib/common.sh"

init_database

menu_principal() {
    while true; do
        clear
        echo "=========================================="
        echo "   SYSTÈME DE GESTION CIDST V3.0"
        echo "   Administration sécurisée"
        echo "=========================================="
        echo ""
        echo "1. Ajouter un utilisateur"
        echo "2. Modifier un utilisateur"
        echo "3. Supprimer un utilisateur (désactiver)"
        echo "4. Lister les utilisateurs"
        echo "5. Changer mot de passe utilisateur"
        echo "6. Voir logs d'audit"
        echo "7. Exporter vers ancien format (compatibilité)"
        echo "8. Quitter"
        echo ""
        read -rp "Choix : " choix
        
        case "$choix" in
            1) ajouter_interactif ;;
            2) modifier_interactif ;;
            3) supprimer_interactif ;;
            4) lister_utilisateurs ;;
            5) changer_mdp_interactif ;;
            6) voir_audit ;;
            7) exporter_compat ;;
            8) exit 0 ;;
            *) echo "Choix invalide" ; sleep 1 ;;
        esac
    done
}

ajouter_interactif() {
    read -rp "Nom d'utilisateur : " nom
    read -rsp "Mot de passe : " mdp1; echo
    read -rsp "Confirmer mot de passe : " mdp2; echo
    
    [ "$mdp1" != "$mdp2" ] && { echo "Mots de passe différents"; return; }
    [ ${#mdp1} -lt 8 ] && { echo "Minimum 8 caractères"; return; }
    
    echo "Groupes disponibles :"
    sqlite3 "$DB_FILE" "SELECT nom FROM groupes;"
    read -rp "Groupe : " groupe
    
    echo "Rôles : pdg, chef, employe"
    read -rp "Rôle : " role
    
    db_ajouter_utilisateur "$nom" "$mdp1" "$groupe" "$role"
    echo "✓ Utilisateur $nom ajouté avec succès"
    sleep 1
}

changer_mdp_interactif() {
    read -rp "Nom d'utilisateur : " nom
    read -rsp "Nouveau mot de passe : " mdp1; echo
    read -rsp "Confirmer : " mdp2; echo
    
    [ "$mdp1" != "$mdp2" ] && { echo "Erreur"; return; }
    
    db_modifier_utilisateur "$nom" "motdepasse" "$mdp1"
    # Forcer changement à prochaine connexion Linux
    passwd -e "$nom" 2>/dev/null || true
    echo "✓ Mot de passe changé. L'utilisateur devra le modifier à la prochaine connexion."
    sleep 1
}

voir_audit() {
    echo "=== LOGS D'AUDIT (30 derniers) ==="
    sqlite3 "$DB_FILE" "SELECT datetime(timestamp), action, utilisateur_cible, details FROM audit_log ORDER BY timestamp DESC LIMIT 30;"
    read -rp "Appuyez sur Entrée..."
}

modifier_interactif() {
    read -rp "Nom d'utilisateur à modifier : " nom
    
    echo "Que voulez-vous modifier ?"
    echo "1. Groupe"
    echo "2. Rôle"
    echo "3. Statut"
    read -rp "Choix : " modif
    
    case "$modif" in
        1)
            echo "Groupes disponibles :"
            sqlite3 "$DB_FILE" "SELECT nom FROM groupes;"
            read -rp "Nouveau groupe : " groupe
            db_modifier_utilisateur "$nom" "groupe" "$groupe"
            echo "✓ Groupe modifié"
            ;;
        2)
            echo "Rôles : pdg, chef, employe"
            read -rp "Nouveau rôle : " role
            db_modifier_utilisateur "$nom" "role" "$role"
            echo "✓ Rôle modifié"
            ;;
        3)
            echo "Statuts : actif, inactif"
            read -rp "Nouveau statut : " statut
            db_modifier_utilisateur "$nom" "statut" "$statut"
            echo "✓ Statut modifié"
            ;;
    esac
    sleep 1
}

supprimer_interactif() {
    read -rp "Nom d'utilisateur à désactiver : " nom
    read -rp "Êtes-vous sûr ? (oui/non) : " confirm
    
    if [ "$confirm" = "oui" ]; then
        db_modifier_utilisateur "$nom" "statut" "inactif"
        echo "✓ Utilisateur $nom désactivé"
    else
        echo "Opération annulée"
    fi
    sleep 1
}

lister_utilisateurs() {
    echo "=== LISTE DES UTILISATEURS ==="
    sqlite3 "$DB_FILE" "SELECT id, nom, groupe, role, statut, datetime(date_creation) FROM utilisateurs ORDER BY nom;"
    echo ""
    read -rp "Appuyez sur Entrée..."
}

exporter_compat() {
    echo "=== EXPORT FORMAT LEGACY CSV ==="
    sqlite3 "$DB_FILE" ".mode csv" "SELECT nom, '', groupe, role FROM utilisateurs WHERE statut='actif';" > "$SCRIPT_DIR/export_users.csv"
    echo "✓ Exporté vers $SCRIPT_DIR/export_users.csv"
    sleep 1
}

# Appel de la fonction principale
menu_principal