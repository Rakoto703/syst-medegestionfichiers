#!/bin/bash
#===============================================================================
# FICHIER: lib/crypto.sh
# DESCRIPTION: CIDST - Fonctions de hachage Argon2id en pur shell
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config.sh"

# Paramètres Argon2id
ARGON2_TIME=3
ARGON2_MEMORY=16      # 2^16 = 65536 KB (64 MB)
ARGON2_PARALLELISM=4
ARGON2_HASH_LEN=32

#-------------------------------
# Générer un salt aléatoire
#-------------------------------
generer_sel() {
    openssl rand -hex 16
}

#-------------------------------
# Hacher un mot de passe
# Usage: hasher_motdepasse "motdepasse" "sel"
# Retour: hash_argon2 complet
#-------------------------------
hasher_motdepasse() {
    local motdepasse="$1"
    local sel="$2"
    
    printf '%s' "$motdepasse$sel" | argon2 "$sel" \
        -id \
        -t "$ARGON2_TIME" \
        -m "$ARGON2_MEMORY" \
        -p "$ARGON2_PARALLELISM" \
        -l "$ARGON2_HASH_LEN" \
        -e
}

#-------------------------------
# Vérifier un mot de passe
# Usage: verifier_motdepasse "motdepasse" "sel" "hash_stocké"
# Retour: 0 si OK, 1 si KO
#-------------------------------
verifier_motdepasse() {
    local motdepasse="$1"
    local sel="$2"
    local hash="$3"
    
    printf '%s' "$motdepasse$sel" | argon2 "$sel" -id -v "$hash" 2>/dev/null | grep -q "Verified ok"
}

#-------------------------------
# Test rapide
#-------------------------------
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "Test Argon2 shell..."
    sel=$(generer_sel)
    hash=$(hasher_motdepasse "TestCIDST123!" "$sel")
    echo "Sel: $sel"
    echo "Hash: $hash"
    
    if verifier_motdepasse "TestCIDST123!" "$sel" "$hash"; then
        echo "✓ Vérification OK"
    else
        echo "✗ Vérification ÉCHEC"
        exit 1
    fi
    
    if ! verifier_motdepasse "MauvaisPass" "$sel" "$hash"; then
        echo "✓ Rejet mot de passe incorrect OK"
    else
        echo "✗ Rejet ÉCHEC"
        exit 1
    fi
fi