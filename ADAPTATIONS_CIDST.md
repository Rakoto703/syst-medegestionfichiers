# Adaptations du Projet pour le CIDST

## Vue d'ensemble
Ce document résume toutes les adaptations effectuées pour transformer le projet "Système de Gestion d'Entreprise V2.0" en un système adapté au **Centre d'Information et de Documentation Scientifique et Technique (CIDST)**.

---

## 1. Modifications structurelles

### 1.1 Chemins système
| Avant | Après |
|-------|-------|
| `/srv/gestion/` | `/srv/cidst/` |
| `/srv/entreprise/` | `/srv/cidst/` |
| `/var/log/gestion_entreprise.log` | `/var/log/cidst_gestion.log` |
| `gestion_entreprise_$$` | `cidst_gestion_$$` |

### 1.2 Services systemd
| Avant | Après |
|-------|-------|
| `gestion-csv-watcher.service` | `cidst-csv-watcher.service` |
| `Surveillance CSV Gestion Entreprise` | `Surveillance CSV Gestion CIDST` |

---

## 2. Structure organisationnelle CIDST

### Services
- `saf` - Service des Affaires Administratives et Financières
- `scrp` - Service Commercial et Relations Publiques  
- `stic` - Service Technologies de l'Information et de la Communication

### Départements techniques
- `dai` - Département Acquisitions de l'Information
- `dti` - Département Traitement de l'Information
- `drsi` - Département Réseaux et Système d'Information
- `ddi` - Département Diffusion de l'Information
- `dvrre` - Département Valorisation des Résultats de Recherche et Edition

### Unités spécialisées
- `cati` - Centre d'Appui à la Technologie et à l'Innovation
- `direction` - Direction générale
- Antennes régionales : Fianarantsoa, Toamasina, Mahajanga

---

## 3. Fichiers modifiés

### 3.1 Fichiers de configuration

#### `config.sh` ✅
**Modifications :**
- En-tête : "Configuration centralisée CIDST V2.0"
- Chemins : `/srv/cidst/`, `/var/log/cidst_gestion.log`
- Groupe : `cidst` (au lieu de `entreprise`)
- Nouveau bloc : Liste des groupes CIDST (Services + Départements + Antennes)

**Avant :**
```bash
export DOSSIER_BASE="/srv/entreprise"
export GROUPE_ENTREPRISE="entreprise"
```

**Après :**
```bash
export DOSSIER_BASE="/srv/cidst"
export GROUPE_ENTREPRISE="cidst"
export GROUPS_CIDST=(
    "direction"
    "saf", "scrp", "stic", "dai", "dti", "drsi", "ddi", "dvrre"
    "cati"
    "antenne_fianarantsoa", "antenne_toamasina", "antenne_mahajanga"
)
```

#### `README.md` ✅
**Modifications :**
- Titre : "Système de Gestion **CIDST** Linux V2.0"
- Nouvelle section : "Structure du CIDST" (détails Services/Départements)
- Chemin architecture : `/srv/cidst/`
- Format CSV : exemple adapté à CIDST

#### `FONCTIONNEMENT_CIDST.txt` (NEW FILE) ✅
**Création d'un nouveau document complet :**
- Structure organisationnelle CIDST détaillée
- Architecture modulaire adaptée au CIDST
- Flux d'exécution pour gestion Services/Départements
- Configuration Samba pour partages documentaires
- Référentiels : SAF, SCRP, STIC, DAI, DTI, DRSI, DDI, DVRRE, CATI
- Antennes régionales : Fianarantsoa, Toamasina, Mahajanga

### 3.2 Scripts d'installation et orchestration

#### `install.sh` ✅
**Modifications :**
- En-tête : "Script d'installation du système de gestion **CIDST** V2.0"
- Chemins : `/srv/cidst/` (au lieu de `/srv/gestion/`)
- Service systemd : `cidst-csv-watcher.service` (au lieu de `gestion-csv-watcher`)
- CSV exemple : Structure CIDST (30 utilisateurs pour tous les services/départements)
- Messages : "Installation CIDST terminée!", logs vers `/var/log/cidst_gestion.log`

#### `main.sh` ✅
**Modifications :**
- En-tête : "Script principal de gestion **CIDST** V2.0"
- Commentaire : "FONCTION PRINCIPALE - CIDST"

#### `csv_watcher.sh` ✅
**Modifications :**
- En-tête : "Surveillance temps réel du CSV (CIDST)"

### 3.3 Fichiers de configuration Samba

#### `samba.sh` ✅
**Modifications majeures :**
- En-tête : Mention du CIDST et ses Services/Départements
- Marqueurs : `### CIDST START ###` / `### CIDST END ###` (au lieu de ENTREPRISE)
- Partage principal : `[CIDST_Central]` (au lieu de [Entreprise])
- Noms lisibles des partages avec descriptions :
  - `[saf]` → "SAF - Affaires Admin Financières"
  - `[scrp]` → "SCRP - Commercial Relations"
  - `[stic]` → "STIC - Technologies Information"
  - `[dai]` → "DAI - Acquisitions Information"
  - `[dti]` → "DTI - Traitement Information"
  - `[drsi]` → "DRSI - Réseaux Système Info"
  - `[ddi]` → "DDI - Diffusion Information"
  - `[dvrre]` → "DVRRE - Valorisation Recherche"
  - `[cati]` → "CATI - Tech Innovation"
  - Antennes régionales avec noms complets

### 3.4 Fichiers de sécurité

#### `security.sh` ✅
**Modifications :**
- En-tête : "CIDST - Mesures de sécurité renforcées V2.0"
- Log section : "SÉCURISATION DES PERMISSIONS CIDST"
- Fichier limites : `/etc/security/limits.d/cidst.conf` (au lieu de `entreprise.conf`)
- Commentaires : référence aux utilisateurs CIDST

### 3.5 Autres fichiers (en-têtes)

#### `cleanup.sh` ✅
En-tête : "Nettoyage des utilisateurs/groupes orphelins **CIDST** V2.0"

#### `antivirus.sh` ✅
En-tête : "CIDST - CLAMAV V2.0"

#### `directory.sh` ✅
En-tête : "CIDST - Gestion des dossiers, permissions et ACL V2.0"

#### `archive.sh` ✅
En-tête : "CIDST - Gestion des archives de suppression V2.0"

#### `monitor.sh` ✅
En-tête : "CIDST - Monitoring des ressources système V2.0"

#### `firewall.sh` ✅
En-tête : "CIDST - UFW sécurisé V2.0"

#### `group.sh` ✅
En-tête : "CIDST - Gestion des groupes Linux (Services/Départements) V2.0"

#### `user.sh` ✅
En-tête : "CIDST - Gestion des utilisateurs Linux et Samba V2.0"

#### `common.sh` ✅
En-tête : "CIDST - Fonctions utilitaires communes V2.0"

---

## 4. Utilisateurs et groupes - Fichier `users.csv`

### Structure CSV adaptée (VIDE - à remplir par l'administrateur)
```csv
# Fichier CSV des utilisateurs CIDST
# Format: nom,motdepasse,groupe,role
# Rôles: pdg (Directeur), chef (Chef service/département), employe (Agent)
# Groupes: direction, saf, scrp, stic, dai, dti, drsi, ddi, dvrre, cati, antenne_fianarantsoa, antenne_toamasina, antenne_mahajanga

# EXEMPLE (à adapter selon vos besoins):
# directeur_cidst,SecureP@ss123!,direction,pdg
# saf_chef,SecureP@ss123!,saf,chef
# admin_saf1,SecureP@ss123!,saf,employe
```

**Note importante :** Le fichier CSV est maintenant vide par défaut. L'administrateur doit le remplir selon les besoins réels du CIDST avant de lancer le système.

### Rôles

| Rôle | Description |
|------|-------------|
| `pdg` | Directeur général du CIDST ; administrateur système ; propriétaire des archives |
| `chef` | Chef de service/département ; accès rw complet sur dossier du groupe |
| `employe` | Agent ; accès aux partages collectifs et documents archivés du service |

---

## 5. Structure de répertoires `/srv/cidst/`

```
/srv/cidst/
├── _archive/                          # Archives suppressions (root)
├── partages_collectifs/               # Partages communs tous services
├── saf/partages/ & archives/          # Service Affaires Admin
├── scrp/partages/ & archives/         # Service Commercial
├── stic/partages/, archives/ & securise/ # Service TIC
├── dai/partages/ & archives/          # Département Acquisitions
├── dti/partages/ & archives/          # Département Traitement
├── drsi/partages/, archives/ & systeme/ # Département Réseaux
├── ddi/partages/ & archives/          # Département Diffusion
├── dvrre/partages/, archives/ & publications/ # Département Valorisation
├── cati/partages/, archives/ & brevets/  # Centre Tech Innovation
└── antennes/
    ├── fianarantsoa/
    ├── toamasina/
    └── mahajanga/
```

---

## 6. Partages Samba CIDST

### Partages Services/Départements

| Nom Samba | Chemin | Groupe | Descriptif |
|-----------|--------|--------|-----------|
| `[SAF_Partage]` | `/srv/cidst/saf` | `@saf` | Service Affaires Administratives |
| `[SCRP_Partage]` | `/srv/cidst/scrp` | `@scrp` | Service Commercial |
| `[STIC_Partage]` | `/srv/cidst/stic` | `@stic` | Service Technologies |
| `[DAI_Partage]` | `/srv/cidst/dai` | `@dai` | Acquisitions Information |
| `[DTI_Partage]` | `/srv/cidst/dti` | `@dti` | Traitement Information |
| `[DRSI_Partage]` | `/srv/cidst/drsi` | `@drsi` | Réseaux Système |
| `[DDI_Partage]` | `/srv/cidst/ddi` | `@ddi` | Diffusion Information |
| `[DVRRE_Partage]` | `/srv/cidst/dvrre` | `@dvrre` | Valorisation Recherche |
| `[CATI_Brevets]` | `/srv/cidst/cati/brevets` | `@cati` | Fonds brevets/propriété intellec. |
| Antennes | `/srv/cidst/antennes/` | Antenne | Ressources régionales |

### Configuration SMB3 sécurisée

- Minimum protocol : **SMB3_11**
- Chiffrement : **required**
- NTLM : **NTLMv2 seulement**
- Signing : **mandatory**
- Access : restrictif avec déni automatique

---

## 7. Checkliste de migration

- ✅ fichiers de configuration (config.sh, main.sh)
- ✅ Installation (install.sh) 
- ✅ Documentation (README.md, FONCTIONNEMENT_CIDST.txt)
- ✅ Utilisateurs/Groupes (users.csv)
- ✅ Samba/Partages (samba.sh)
- ✅ Sécurité (security.sh, firewall.sh, antivirus.sh)
- ✅ Gestion (user.sh, group.sh, directory.sh, archive.sh)
- ✅ Surveillance (monitor.sh, csv_watcher.sh, cleanup.sh)
- ✅ Utilitaires (common.sh)

---

## 8. Utilisation - Démarrage CIDST

### Installation
```bash
sudo bash install.sh
```

### ⚠️ Configuration obligatoire par l'administrateur

**IMPORTANT :** Avant de lancer le système, l'administrateur doit configurer le fichier CSV :

```bash
sudo nano /srv/cidst/users.csv
```

Le fichier est créé vide avec des commentaires explicatifs. L'administrateur doit y ajouter tous les utilisateurs réels du CIDST selon le format documenté.

### Lancement manuel (après configuration CSV)
```bash
sudo /srv/cidst/main.sh
```

### Surveillance temps réel (watcher)
```bash
sudo systemctl start cidst-csv-watcher.service
sudo systemctl status cidst-csv-watcher.service
```

### Modification des utilisateurs
Éditer `/srv/cidst/users.csv` et le watcher appliquera automatiquement les modifications

### Vérification logs
```bash
tail -f /var/log/cidst_gestion.log
grep "ERREUR" /var/log/cidst_gestion.log
```

---

## 9. Notes importantes

1. **Sécurité** : Les mots de passe dans users.csv doivent être renforcés en production
2. **Montages** : Ajouter opciones `noexec,nodev,nosuid` à `/etc/fstab` pour `/srv/cidst/`
3. **Politique** : Adapter selon les règles de gouvernance CIDST
4. **Sauvegarde** : Archives automatiques dans `/srv/cidst/_archive/`
5. **Audit** : Tous les logs centralisés dans `/var/log/cidst_gestion.log`

---

**Date d'adaptation :** Avril 2026  
**Version projet :** V2.0 CIDST  
**Organisme :** Centre d'Information et de Documentation Scientifique et Technique

