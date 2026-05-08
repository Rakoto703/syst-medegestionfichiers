#!/bin/bash
#===============================================================================
# FICHIER: lib/database.sh
# DESCRIPTION: CIDST - Gestion base de données SQLite V3.0 (pur shell)
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/crypto.sh"

DB_FILE="${DOSSIER_BASE}/cidst.db"

#-------------------------------
# Initialisation base de données
#-------------------------------
init_database() {
    if [ ! -f "$DB_FILE" ]; then
        sqlite3 "$DB_FILE" << 'EOF'
            PRAGMA foreign_keys = ON;
            PRAGMA journal_mode = WAL;
            
            CREATE TABLE IF NOT EXISTS utilisateurs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nom TEXT UNIQUE NOT NULL COLLATE NOCASE,
                mot_deplace_hash TEXT NOT NULL,
                sel TEXT NOT NULL,
                groupe TEXT NOT NULL,
                role TEXT NOT NULL CHECK(role IN ('pdg','chef','employe')),
                actif INTEGER DEFAULT 1,
                date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS groupes (
                nom TEXT PRIMARY KEY,
                description TEXT,
                type TEXT CHECK(type IN ('service','departement','unite','antenne'))
            );
            
            CREATE TABLE IF NOT EXISTS audit_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                action TEXT NOT NULL,
                utilisateur_cible TEXT,
                admin_executant TEXT,
                details TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE INDEX IF NOT EXISTS idx_users_groupe ON utilisateurs(groupe);
            CREATE INDEX IF NOT EXISTS idx_users_actif ON utilisateurs(actif);
            CREATE INDEX IF NOT EXISTS idx_audit_time ON audit_log(timestamp);
            
            -- Insertion groupes CIDST par défaut
            INSERT OR IGNORE INTO groupes (nom, description, type) VALUES
            ('direction', 'Direction générale', 'service'),
            ('saf', 'Service Affaires Administratives et Financières', 'service'),
            ('scrp', 'Service Commercial et Relations Publiques', 'service'),
            ('stic', 'Service Technologies Information et Communication', 'service'),
            ('dai', 'Département Acquisitions de l''Information', 'departement'),
            ('dti', 'Département Traitement de l''Information', 'departement'),
            ('drsi', 'Département Réseaux et Système d''Information', 'departement'),
            ('ddi', 'Département Diffusion de l''Information', 'departement'),
            ('dvrre', 'Département Valorisation Recherche et Edition', 'departement'),
            ('cati', 'Centre d''Appui à la Technologie et à l''Innovation', 'unite'),
            ('antenne_fianarantsoa', 'Antenne régionale Fianarantsoa', 'antenne'),
            ('antenne_toamasina', 'Antenne régionale Toamasina', 'antenne'),
            ('antenne_mahajanga', 'Antenne régionale Mahajanga', 'antenne');
EOF
        chmod 600 "$DB_FILE"
        log_info "Base de données CIDST initialisée"
    fi
}

#-------------------------------
# Échappement SQL
#-------------------------------
sql_escape() {
    local value="$1"
    printf '%s' "${value//\'/''}"
}

#-------------------------------
# CRUD Utilisateurs
#-------------------------------
db_ajouter_utilisateur() {
    local nom="$1"
    local motdepasse="$2"
    local groupe="$3"
    local role="$4"
    
    local sel hash
    sel=$(generer_sel)
    hash=$(hasher_motdepasse "$motdepasse" "$sel")
    
    sqlite3 "$DB_FILE" << EOF
        INSERT INTO utilisateurs (nom, mot_deplace_hash, sel, groupe, role)
        VALUES ('$(sql_escape "$nom")', '$(sql_escape "$hash")', '$(sql_escape "$sel")', '$(sql_escape "$groupe")', '$(sql_escape "$role")');
        
        INSERT INTO audit_log (action, utilisateur_cible, details)
        VALUES ('CREATE', '$(sql_escape "$nom")', 'Groupe: $(sql_escape "$groupe"), Role: $(sql_escape "$role")');
EOF
}

db_modifier_utilisateur() {
    local nom="$1"
    local champ="$2"
    local valeur="$3"

    case "$champ" in
        groupe|role)
            sqlite3 "$DB_FILE" "UPDATE utilisateurs SET $champ='$(sql_escape "$valeur")', date_modification=datetime('now') WHERE nom='$(sql_escape "$nom")';"
            ;;
        motdepasse)
            local sel hash
            sel=$(generer_sel)
            hash=$(hasher_motdepasse "$valeur" "$sel")
            sqlite3 "$DB_FILE" "UPDATE utilisateurs SET mot_deplace_hash='$(sql_escape "$hash")', sel='$(sql_escape "$sel")', date_modification=datetime('now') WHERE nom='$(sql_escape "$nom")';"
            ;;
        *)
            log_error "Champ de mise à jour non autorisé: $champ"
            return 1
            ;;
    esac
    
    sqlite3 "$DB_FILE" "INSERT INTO audit_log (action, utilisateur_cible, details) VALUES ('UPDATE', '$(sql_escape "$nom")', 'Champ: $(sql_escape "$champ")');"
}

db_supprimer_utilisateur() {
    local nom="$1"
    sqlite3 "$DB_FILE" "UPDATE utilisateurs SET actif=0, date_modification=datetime('now') WHERE nom='$(sql_escape "$nom")';"
    sqlite3 "$DB_FILE" "INSERT INTO audit_log (action, utilisateur_cible, details) VALUES ('DELETE', '$(sql_escape "$nom")', 'Soft delete');"
}

db_lister_utilisateurs() {
    sqlite3 "$DB_FILE" "SELECT nom, groupe, role, actif, date_creation FROM utilisateurs WHERE actif=1 ORDER BY groupe, role, nom;"
}

db_exporter_pour_scripts() {
    sqlite3 -csv "$DB_FILE" "SELECT nom, groupe, role FROM utilisateurs WHERE actif=1 ORDER BY groupe, nom;"
}

#-------------------------------
# Audit et traçabilité
#-------------------------------
db_log_audit() {
    local action="$1"
    local cible="$2"
    local details="$3"
    sqlite3 "$DB_FILE" "INSERT INTO audit_log (action, utilisateur_cible, admin_executant, details) VALUES ('$(sql_escape "$action")', '$(sql_escape "$cible")', '$(sql_escape "$(whoami)")', '$(sql_escape "$details")');"
}