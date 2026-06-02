# 🚀 Système de Gestion CIDST Linux V3.0
# 🚀 Système de Gestion CIDST Linux V3.0

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

> **Système modulaire et sécurisé** pour la gestion centralisée du Centre d'Information et de Documentation Scientifique et Technique (CIDST) : utilisateurs, groupes, partages Samba, antennes régionales et sécurité sur Linux Ubuntu avec base de données SQLite.
[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

> **Système modulaire et sécurisé** pour la gestion centralisée du Centre d'Information et de Documentation Scientifique et Technique (CIDST) : utilisateurs, groupes, partages Samba, antennes régionales et sécurité sur Linux Ubuntu avec base de données SQLite.

## ✨ Nouveautés V3.0

- 🗄️ **Base de données SQLite** : Gestion persistante des utilisateurs avec audit trail complet
- 🖥️ **Interface d'administration** : Console interactive pour la gestion des utilisateurs
- 🔐 **Hachage sécurisé** : Argon2id + salt pour les mots de passe
- 📊 **Audit complet** : Traçabilité de toutes les opérations administratives
- ⚡ **Installation automatisée Ubuntu** : Déploiement one-click avec toutes les dépendances
## ✨ Nouveautés V3.0

- 🗄️ **Base de données SQLite** : Gestion persistante des utilisateurs avec audit trail complet
- 🖥️ **Interface d'administration** : Console interactive pour la gestion des utilisateurs
- 🔐 **Hachage sécurisé** : Argon2id + salt pour les mots de passe
- 📊 **Audit complet** : Traçabilité de toutes les opérations administratives
- ⚡ **Installation automatisée Ubuntu** : Déploiement one-click avec toutes les dépendances

## 🏗️ Architecture
## 🏗️ Architecture

```
/srv/cidst/
├── config.sh          # ⚙️ Configuration centralisée
├── main.sh            # 🎯 Orchestrateur principal
├── admin_cidst.sh     # 👨‍💼 Interface d'administration interactive
├── csv_watcher.sh     # 👀 Surveillance temps réel du CSV (legacy)
├── install.sh         # 📦 Installateur Ubuntu automatisé
├── cidst.db           # 🗃️ Base de données SQLite (source de vérité)
├── config.sh          # ⚙️ Configuration centralisée
├── main.sh            # 🎯 Orchestrateur principal
├── admin_cidst.sh     # 👨‍💼 Interface d'administration interactive
├── csv_watcher.sh     # 👀 Surveillance temps réel du CSV (legacy)
├── install.sh         # 📦 Installateur Ubuntu automatisé
├── cidst.db           # 🗃️ Base de données SQLite (source de vérité)
└── lib/
    ├── common.sh      # 🛠️ Utilitaires et validation
    ├── database.sh    # 💾 Gestion SQLite + audit
    ├── user.sh        # 👤 CRUD utilisateurs Linux + Samba
    ├── group.sh       # 👥 CRUD groupes Linux
    ├── directory.sh   # 📁 Gestion dossiers et ACL
    ├── archive.sh     # 📦 Archivage suppressions
    ├── samba.sh       # 🌐 Configuration SMB3 sécurisée
    ├── cleanup.sh     # 🧹 Nettoyage orphelins + malwares
    ├── monitor.sh     # 📈 Monitoring ressources
    ├── antivirus.sh   # 🛡️ ClamAV + cron
    ├── firewall.sh    # 🔥 UFW restrictif
    └── security.sh    # 🔒 Renforcement système
    ├── common.sh      # 🛠️ Utilitaires et validation
    ├── database.sh    # 💾 Gestion SQLite + audit
    ├── user.sh        # 👤 CRUD utilisateurs Linux + Samba
    ├── group.sh       # 👥 CRUD groupes Linux
    ├── directory.sh   # 📁 Gestion dossiers et ACL
    ├── archive.sh     # 📦 Archivage suppressions
    ├── samba.sh       # 🌐 Configuration SMB3 sécurisée
    ├── cleanup.sh     # 🧹 Nettoyage orphelins + malwares
    ├── monitor.sh     # 📈 Monitoring ressources
    ├── antivirus.sh   # 🛡️ ClamAV + cron
    ├── firewall.sh    # 🔥 UFW restrictif
    └── security.sh    # 🔒 Renforcement système
```

## 🏢 Structure du CIDST

### Services
| Service | Description |
|---------|-------------|
| **SAF** | Service des Affaires Administratives et Financières |
| **SCRP** | Service Commercial et Relations Publiques |
| **STIC** | Service Technologies de l'Information et de la Communication |

### Départements
| Département | Description |
|-------------|-------------|
| **DAI** | Département Acquisitions de l'Information |
| **DTI** | Département Traitement de l'Information |
| **DRSI** | Département Réseaux et Système d'Information |
| **DDI** | Département Diffusion de l'Information |
| **DVRRE** | Département Valorisation des Résultats de Recherche et Edition |

### Unités Spécialisées
- **CATI** : Centre d'Appui à la Technologie et à l'Innovation
- **Antennes régionales** : Fianarantsoa, Toamasina, Mahajanga
## 🏢 Structure du CIDST

### Services
| Service | Description |
|---------|-------------|
| **SAF** | Service des Affaires Administratives et Financières |
| **SCRP** | Service Commercial et Relations Publiques |
| **STIC** | Service Technologies de l'Information et de la Communication |

### Départements
| Département | Description |
|-------------|-------------|
| **DAI** | Département Acquisitions de l'Information |
| **DTI** | Département Traitement de l'Information |
| **DRSI** | Département Réseaux et Système d'Information |
| **DDI** | Département Diffusion de l'Information |
| **DVRRE** | Département Valorisation des Résultats de Recherche et Edition |

### Unités Spécialisées
- **CATI** : Centre d'Appui à la Technologie et à l'Innovation
- **Antennes régionales** : Fianarantsoa, Toamasina, Mahajanga

## 🗄️ Base de Données SQLite
## 🗄️ Base de Données SQLite

Le système utilise SQLite pour une gestion persistante et sécurisée des utilisateurs :

- **📁 Fichier** : `/srv/cidst/cidst.db`
- **📋 Tables** :
- **📁 Fichier** : `/srv/cidst/cidst.db`
- **📋 Tables** :
  - `utilisateurs` : Utilisateurs actifs avec hachage Argon2id + salt
  - `groupes` : Définition des groupes CIDST
  - `audit_log` : Traçabilité complète des opérations
- **🚀 Fonctionnalités** :
  - 🔐 Hachage sécurisé des mots de passe
  - 📊 Audit trail complet
  - ✅ Contraintes d'intégrité
  - ⚡ Index optimisés
  - 🔄 Mode WAL pour les performances
- **🚀 Fonctionnalités** :
  - 🔐 Hachage sécurisé des mots de passe
  - 📊 Audit trail complet
  - ✅ Contraintes d'intégrité
  - ⚡ Index optimisés
  - 🔄 Mode WAL pour les performances

## 📄 Format CSV (Legacy)
## 📄 Format CSV (Legacy)

⚠️ **Le CSV est maintenant optionnel** - la gestion se fait via l'interface d'administration.

Le fichier `users.csv` peut toujours être utilisé pour l'import initial :

```csv
# Fichier CSV des utilisateurs CIDST
# Format: nom,motdepasse,groupe,role
# Rôles: pdg (Directeur), chef (Chef service/département), employe (Agent)
# Groupes: direction, saf, scrp, stic, dai, dti, drsi, ddi, dvrre, cati, antenne_fianarantsoa, antenne_toamasina, antenne_mahajanga

# EXEMPLE (à adapter selon vos besoins):
directeur_cidst,SecureP@ss123!,direction,pdg
saf_chef,SecureP@ss123!,saf,chef
admin_saf1,SecureP@ss123!,saf,employe
```

**👥 Rôles:**
- `pdg` : Directeur général, administrateur système, propriétaire des archives
**👥 Rôles:**
- `pdg` : Directeur général, administrateur système, propriétaire des archives
- `chef` : Chef de service/département, accès rw sur dossier du groupe
- `employe` : Agent, accès à dossiers de travail collaboratif et archives documentaires

## 🖥️ Interface d'Administration
## 🖥️ Interface d'Administration

### 🚀 Lancement de l'interface
### 🚀 Lancement de l'interface

```bash
sudo /srv/cidst/admin_cidst.sh
```

### 📋 Menu Principal

```
=== GESTION CIDST V3.0 - Interface d'Administration ===

1. 📊 Afficher tous les utilisateurs
2. ➕ Ajouter un utilisateur
3. ✏️ Modifier un utilisateur
4. 🗑️ Supprimer un utilisateur
5. 🔍 Rechercher un utilisateur
6. 📋 Importer depuis CSV
7. 💾 Exporter vers CSV
8. 📈 Afficher le journal d'audit
9. 🔄 Synchroniser avec le système
0. 🚪 Quitter

Choix :
```

### 🔧 Fonctionnalités

- **Gestion complète des utilisateurs** : CRUD avec validation
- **Synchronisation automatique** : Utilisateurs Linux + Samba + groupes
- **Audit en temps réel** : Toutes les actions tracées
- **Import/Export CSV** : Compatibilité legacy
- **Interface interactive** : Navigation facile avec menus numérotés

## 📦 Installation

### Prérequis
- Ubuntu 20.04+ ou Debian 11+
- Droits root (sudo)
- Connexion internet pour les dépendances

### Installation Automatisée

```bash
# Télécharger le dépôt
git clone https://github.com/Rakoto703/syst-medegestionfichiers.git
cd syst-medegestionfichiers

# Lancer l'installation (nécessite root)
sudo ./install.sh
```

### Installation Manuelle

```bash
# Installer les dépendances
sudo apt update
sudo apt install -y samba samba-common-bin clamav clamav-daemon sqlite3 python3 python3-argon2-cffi openssh-server ufw inotify-tools

# Créer la structure
sudo mkdir -p /srv/cidst/lib

# Copier les fichiers
sudo cp config.sh main.sh csv_watcher.sh admin_cidst.sh /srv/cidst/
sudo cp lib/*.sh /srv/cidst/lib/

# Configurer les permissions
sudo chmod 750 /srv/cidst
sudo chmod 700 /srv/cidst/*.sh
sudo chmod 644 /srv/cidst/config.sh
sudo chmod 755 /srv/cidst/lib
sudo chmod 644 /srv/cidst/lib/*.sh

# Initialiser la base de données
sudo /srv/cidst/lib/database.sh
```

## 🧭 Manuel d'utilisation

### 1. Démarrage du système

```bash
# Via l'interface d'administration (recommandé)
sudo /srv/cidst/admin_cidst.sh

# Via le script principal (legacy)
sudo /srv/cidst/main.sh
```

### 2. Vérifier le fonctionnement

```bash
sudo systemctl status cidst-monitoring
sudo systemctl status cidst-cleanup.timer
sudo systemctl status cidst-antivirus.timer
sudo journalctl -u cidst-monitoring -f
```

### 3. Ajouter / modifier / supprimer un utilisateur

- Lancement de l'interface : `sudo /srv/cidst/admin_cidst.sh`
- Suivez les choix du menu pour :
  - ajouter un utilisateur
  - modifier un compte
  - désactiver/supprimer un utilisateur
  - consulter le journal d'audit

### 4. Import CSV (optionnel)

Le format CSV est conservé pour la compatibilité, mais il n'est plus obligatoire.

```csv
nom,motdepasse,groupe,role
utilisateur1,MonMotDePasse123!,saf,chef
utilisateur2,AutreMotDePasse456!,dai,employe
```

Puis lancer :

```bash
sudo /srv/cidst/main.sh
```

### 5. Résoudre un CPU à 100 %

Le monitoring calcule maintenant l'utilisation CPU sur plusieurs échantillons, ce qui évite les faux positifs.

Si le CPU reste réellement à 100 % :

```bash
top
ps aux --sort=-%cpu | head -10
```

- Identifiez les processus les plus gourmands
- Arrêtez ou redémarrez les services non nécessaires
- Vérifiez que `sshd`, `smbd`, `nmbd`, `cron`, `rsyslog` sont actifs

### 6. Consultation des logs

```bash
tail -f /var/log/cidst_gestion.log
sudo journalctl -u cidst-monitoring -f
```

### 7. Nettoyage et maintenance

Le système exécute automatiquement :

- un timer de nettoyage quotidien
- un timer antivirus hebdomadaire
- un monitoring continu des ressources

Pour forcer une vérification manuelle :

```bash
sudo systemctl restart cidst-monitoring
sudo systemctl restart cidst-cleanup.timer
sudo systemctl restart cidst-antivirus.timer
```

### 8. Bonnes pratiques

- Utilisez des mots de passe forts
- Vérifiez les permissions de `/srv/cidst`
- Sauvegardez régulièrement `/srv/cidst/cidst.db`
- Conservez les logs et audits pour l'analyse

### Services Système

Le système inclut des services automatiques pour un fonctionnement 24/7 :

```bash
# État des services
sudo systemctl status cidst-monitoring
sudo systemctl status cidst-cleanup.timer
sudo systemctl status cidst-antivirus.timer

# Logs temps réel
sudo journalctl -u cidst-* -f
```

### Gestion des Utilisateurs

```bash
# Ajouter un utilisateur
sudo /srv/cidst/admin_cidst.sh
# Sélectionner "2. Ajouter un utilisateur"

# Modifier un utilisateur
sudo /srv/cidst/admin_cidst.sh
# Sélectionner "3. Modifier un utilisateur"

# Supprimer un utilisateur
sudo /srv/cidst/admin_cidst.sh
# Sélectionner "4. Supprimer un utilisateur"
```

## 🔒 Sécurité

### Fonctionnalités de Sécurité

- **🔐 Hachage Argon2id** : Mots de passe sécurisés avec salt
- **🛡️ Antivirus intégré** : ClamAV avec scans hebdomadaires
- **🔥 Pare-feu restrictif** : UFW configuré pour accès minimal
- **📊 Audit trail** : Traçabilité complète des opérations
- **🧹 Nettoyage automatique** : Suppression des données orphelines
- **👀 Monitoring continu** : Surveillance des ressources système

### Bonnes Pratiques

- Utilisez des mots de passe forts (12+ caractères)
- Changez régulièrement les mots de passe administrateur
- Vérifiez régulièrement les logs d'audit
- Maintenez le système à jour
- Effectuez des sauvegardes régulières de `/srv/cidst/cidst.db`

## 📊 Monitoring et Logs

### Logs Disponibles

- **📁 Log principal** : `/var/log/cidst_gestion.log`
- **📋 Logs système** : `journalctl -u cidst-*`
- **🗃️ Base d'audit** : Table `audit_log` dans `cidst.db`

### Commandes de Monitoring

```bash
# Afficher les logs en temps réel
tail -f /var/log/cidst_gestion.log

# Afficher les logs système
sudo journalctl -u cidst-monitoring -f

# Vérifier l'état des services
sudo systemctl list-timers
sudo systemctl status cidst-*
```

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Pushez vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

### Directives de Développement

- Suivez les conventions de nommage Bash
- Ajoutez des commentaires explicatifs
- Testez vos modifications
- Mettez à jour la documentation si nécessaire

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 📞 Support

Pour toute question ou problème :

- 📧 **Email** : [votre-email@exemple.com]
- 🐛 **Issues** : [GitHub Issues](https://github.com/Rakoto703/syst-medegestionfichiers/issues)
- 📖 **Documentation** : Voir les fichiers `*.md` dans le dépôt

---

⭐ **Si ce projet vous plaît, n'hésitez pas à lui donner une étoile sur GitHub !**

### Menu Principal

```
==========================================
   SYSTÈME DE GESTION CIDST V3.0
   Administration sécurisée
==========================================

1. Ajouter un utilisateur
2. Modifier un utilisateur
3. Supprimer un utilisateur (désactiver)
4. Lister les utilisateurs
5. Changer mot de passe utilisateur
6. Voir logs d'audit
7. Exporter vers ancien format (compatibilité)
8. Quitter
```

### Fonctionnalités

- **Ajout d'utilisateur** : Création avec validation des groupes et rôles
- **Modification** : Changement de groupe, rôle, ou mot de passe
- **Suppression logique** : Désactivation sans suppression physique
- **Audit complet** : Toutes les actions tracées dans la base
- **Export CSV** : Compatibilité avec l'ancien format si nécessaire

### Sécurité

- Hachage Argon2id + salt pour tous les mots de passe
- Validation anti-injection sur tous les champs
- Audit trail complet avec timestamp et administrateur
- Mode soft delete pour la traçabilité

## Installation et Déploiement 24/7

### Prérequis
- Ubuntu Server 20.04+ ou Debian 11+
- Accès root (sudo)
- Connexion internet pour l'installation des dépendances

### Installation Automatisée

```bash
git clone <repo>
cd gestion-entreprise-v2.0
sudo bash install.sh
```

L'installation configure automatiquement :
- **Installation des dépendances Ubuntu** : samba, clamav, sqlite3, ufw, etc.
- **Initialisation de la base SQLite** avec les groupes CIDST par défaut
- **4 services systemd** pour fonctionnement 24/7
- **2 timers systemd** pour tâches périodiques
- **Surveillance temps réel** du CSV (legacy)
- **Monitoring continu** des ressources
- **Nettoyage automatique** hebdomadaire
- **Scans antivirus** quotidiens

## Configuration Initiale

### Trois approches de démarrage

#### Option 1 : Interface d'Administration (Recommandée)
La méthode moderne et sécurisée :
```bash
sudo /srv/cidst/admin_cidst.sh
```
Permet de créer les utilisateurs directement dans SQLite avec une interface conviviale.

#### Option 2 : Import depuis CSV (Legacy)
Pour importer les utilisateurs existants depuis `users.csv` :
```bash
sudo nano /srv/cidst/users.csv
```
Format obligatoire :
```csv
nom,motdepasse,groupe,role
utilisateur1,MonMotDePasse123!,saf,chef
utilisateur2,AutreMotDePasse456!,dai,employe
```
Puis lancer :
```bash
sudo /srv/cidst/main.sh
```

#### Option 3 : Exploitation directe
Le système fonctionne 100% avec SQLite seul :
```bash
sudo systemctl start cidst-monitoring
```

### Groupes disponibles

- **direction** : Direction générale
- **saf** : Service Affaires Administratives et Financières
- **scrp** : Service Commercial et Relations Publiques
- **stic** : Service Technologies de l'Information et Communication
- **dai** : Département Acquisitions de l'Information
- **dti** : Département Traitement de l'Information
- **drsi** : Département Réseaux et Système d'Information
- **ddi** : Département Diffusion de l'Information
- **dvrre** : Département Valorisation des Résultats de Recherche et Edition
- **cati** : Centre d'Appui à la Technologie et à l'Innovation
- **antenne_fianarantsoa** : Antenne régionale Fianarantsoa
- **antenne_toamasina** : Antenne régionale Toamasina
- **antenne_mahajanga** : Antenne régionale Mahajanga

### Rôles disponibles

- **pdg** : Directeur général (un seul utilisateur)
- **chef** : Chef de service/département
- **employe** : Agent/Employé

## Fonctionnement 24/7

### Services Systemd

Le système comprend 4 services principaux :

1. **cidst-monitoring.service** (Principal) : Monitoring continu des ressources
   - Vérification toutes les 5 minutes
   - Alertes en cas de surcharge
   - Actions d'urgence automatiques
   - **Toujours actif** (source de vérité SQLite)

2. **cidst-csv-watcher.service** (Optionnel) : Surveillance temps réel du CSV
   - Activé seulement si `users.csv` exist et est valide
   - Redémarrage automatique en cas d'erreur
   - Timeout de 30 secondes par opération
   - Permet import/sync legacy CSV → SQLite

3. **cidst-cleanup.service** : Nettoyage automatique
   - Exécution hebdomadaire
   - Suppression des fichiers temporaires
   - Archivage des anciens utilisateurs

4. **cidst-antivirus.service** : Protection antivirus
   - Scans quotidiens complets
   - Mise à jour automatique des signatures
   - Alertes par email

### Timers Systemd

- **cidst-monitoring.timer** : Toutes les 5 minutes
- **cidst-antivirus.timer** : Tous les jours à 02h00

### Gestion des services

```bash
# Vérifier le statut de tous les services
sudo systemctl status cidst-*

# Redémarrer un service spécifique
sudo systemctl restart cidst-csv-watcher

# Consulter les logs d'un service
sudo journalctl -u cidst-monitoring -f

# Désactiver temporairement un service
sudo systemctl stop cidst-antivirus
```

## Intégration SQLite ↔ CSV

### Architecture de données

**Source de vérité** : SQLite (`/srv/cidst/cidst.db`)
- Base de données persistante et transactionnelle
- Toutes les opérations via `admin_cidst.sh` écrites directement ici
- Audit trail complet avec timestamps

**Format Legacy** : CSV (`/srv/cidst/users.csv`) - Optionnel
- Utilisé seulement si présent et valide
- Permet import batch ou import depuis ancien système
- Synchronisé vers SQLite en temps réel via `cidst-csv-watcher`

### Flux de données

```
1. Opération initiale :
   users.csv (si présent et valide) → import SQLite au boot
   └─> cidst.db devient source de vérité

2. Modifications via admin :
   admin_cidst.sh → SQLite directement
   └─> Audit trail généré automatiquement

3. Modifications via CSV (si actif) :
   users.csv (modifié) → cidst-csv-watcher détecte
   └─> Parse CSV → Valide → Insère/Met à jour SQLite
   └─> Génère audit trail

4. Opérations système :
   Tous les services → Lisent uniquement SQLite
   └─> Jamais de dépendance CSV à l'exécution
```

### Fallback automatique

```bash
# Si CSV manquant ou invalide → pas d'erreur
lire_csv()
  │
  ├─ Si users.csv existe ET valide
  │  └─ Utilise contenu CSV
  │
  └─ Sinon
     └─ Bascule vers SQLite
        └─ SELECT FROM utilisateurs WHERE actif=1
```

### Mode Récupération Automatique

En cas de problème, le système peut se récupérer automatiquement :

```bash
# Récupération manuelle
sudo /srv/cidst/recovery.sh

# Ou via le script principal
sudo /srv/cidst/main.sh --recovery
```

La récupération automatique :
- Redémarre les services critiques défaillants
- Vérifie l'intégrité de la base SQLite
- Import optionnel depuis le CSV s'il est présent (legacy)
- Nettoie le système et optimise les performances
- Effectue des tests finaux

## Utilisation

### Exécution manuelle
```bash
sudo /srv/cidst/main.sh
```

### Surveillance automatique (activée par défaut)
Le système surveille automatiquement les modifications du CSV et applique les changements en temps réel.

### Modification des utilisateurs
Éditer `/srv/cidst/users.csv` - le système se met à jour automatiquement via le watcher.

### Monitoring en continu
```bash
# Mode monitoring manuel
sudo /srv/cidst/lib/monitor.sh --continuous

# Vérification des ressources
sudo /srv/cidst/lib/monitor.sh --check
```

## Logs et Monitoring

### Fichiers de logs

- `/var/log/cidst_gestion.log` - Opérations système principales
- `/var/log/csv_changes.log` - Modifications du CSV en temps réel (legacy)
- `/var/log/clamav-daily.log` - Scans antivirus quotidiens
- `journalctl -u cidst-*` - Logs des services systemd

### Audit Database

La base SQLite contient un audit trail complet :

```sql
-- Voir les 10 dernières opérations
sqlite3 /srv/cidst/cidst.db "SELECT datetime(timestamp), action, utilisateur_cible, admin_executant, details FROM audit_log ORDER BY timestamp DESC LIMIT 10;"
```

Types d'actions auditées :
- `CREATE` : Création d'utilisateur
- `UPDATE` : Modification d'utilisateur
- `DELETE` : Suppression logique
- `LOGIN` : Tentatives de connexion (futur)
- `ADMIN` : Actions administratives

### Rotation automatique des logs

- Logs principaux : rotation quotidienne, conservation 30 jours
- Logs CSV : rotation hebdomadaire, conservation 12 semaines
- Compression automatique des anciens logs

### Monitoring des ressources

Le système surveille automatiquement :
- Utilisation CPU (>80% = alerte)
- Utilisation mémoire (>90% = alerte)
- Espace disque (<10% libre = alerte)
- Services critiques (Samba, ClamAV)
- Connexions réseau suspectes

### Alertes et notifications

- **Email** : Alertes antivirus et monitoring
- **Logs** : Tous les événements critiques
- **Actions d'urgence** : Redémarrage automatique des services défaillants

## Dépannage

### Problèmes courants

1. **Service ne démarre pas**
   ```bash
   sudo systemctl status cidst-csv-watcher
   sudo journalctl -u cidst-csv-watcher -n 50
   ```

2. **CSV non pris en compte**
   ```bash
   sudo /srv/cidst/main.sh --recovery
   ```

3. **Partages Samba inaccessibles**
   ```bash
   sudo systemctl restart smbd nmbd
   sudo testparm
   ```

4. **Espace disque critique**
   ```bash
   sudo /srv/cidst/lib/cleanup.sh --emergency
   ```

### Récupération d'urgence

```bash
# Arrêt complet du système
sudo systemctl stop cidst-*

# Récupération complète
sudo /srv/cidst/recovery.sh

# Redémarrage des services
sudo systemctl start cidst-*
```

## Sécurité

- **Base de données** : SQLite avec chiffrement des mots de passe (Argon2id + salt)
- **Audit trail** : Traçabilité complète de toutes les opérations administratives
- **Samba**: SMB3_11 avec chiffrement obligatoire, restriction IP
- **Firewall**: UFW, accès Samba uniquement VLAN interne
- **Antivirus**: ClamAV avec scan quotidien et mise à jour automatique
- **Permissions**: ACL POSIX, sticky bit, noexec recommandé
- **Validation**: Anti-injection sur tous les champs utilisateur
- **Nettoyage**: Suppression auto des fichiers suspects (.exe, .bat, etc.)
- **24/7**: Services systemd avec redémarrage automatique
- **Recovery**: Récupération automatique en cas de panne

## Maintenance

### Tâches automatiques

- **Quotidienne** : Scan antivirus complet à 02h00
- **Hebdomadaire** : Nettoyage complet des fichiers temporaires
- **Mensuelle** : Rotation et archivage des logs
- **Surveillance continue** : Monitoring toutes les 5 minutes

### Maintenance manuelle

```bash
# Mise à jour des signatures antivirus
sudo freshclam

# Nettoyage manuel
sudo /srv/cidst/lib/cleanup.sh

# Vérification complète
sudo /srv/cidst/lib/monitor.sh --full-check
```

## Migration et Compatibilité

### Migration depuis CSV vers SQLite

Si vous aviez un fichier `users.csv` existant :

1. **Sauvegarde** : `cp /srv/cidst/users.csv /srv/cidst/users.csv.backup`
2. **Import** : Le système importe automatiquement lors du premier lancement
3. **Vérification** : Utilisez l'interface admin pour vérifier les utilisateurs

### Compatibilité Legacy

- Le watcher CSV reste actif pour la compatibilité
- Export possible vers CSV via l'interface admin
- Les anciens scripts peuvent coexister

### Mise à Jour V2.0 → V3.0

```bash
# Sauvegarde de l'ancien système
sudo cp -r /srv/cidst /srv/cidst_backup

# Installation de la V3.0
sudo bash install.sh

# Migration des données (si nécessaire)
# Les utilisateurs existants sont automatiquement migrés
```

## License

MIT / Open Source
#   s y s t - m e d e g e s t i o n f i c h i e r s 
 
 