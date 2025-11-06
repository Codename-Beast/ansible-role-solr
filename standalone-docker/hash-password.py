#!/usr/bin/env python3
"""
Password hashing script for Solr BasicAuth
Uses SHA256 double-hashing (same algorithm as Ansible passlib)
Compatible with Solr BasicAuthPlugin
"""

import sys
import hashlib
import base64
from passlib.hash import sha256_crypt

def hash_password_solr(password):
    """
    Hash password using SHA256 with double-hashing for Solr BasicAuth
    This matches Ansible's password_hash('sha512_crypt') behavior
    Format: $5$rounds=5000$SALT$HASH
    """
    # Use sha256_crypt (Solr-compatible)
    # Ansible uses: password_hash('sha512_crypt', 'mysecretsalt')
    # But Solr BasicAuth prefers SHA256
    hashed = sha256_crypt.using(rounds=5000).hash(password)
    return hashed

def hash_password_simple(password):
    """
    Simple SHA256 hash (base64 encoded) - alternative method
    """
    sha256_hash = hashlib.sha256(password.encode('utf-8')).digest()
    return base64.b64encode(sha256_hash).decode('utf-8')

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: hash-password.py <password>", file=sys.stderr)
        sys.exit(1)

    password = sys.argv[1]

    # Use SHA256-crypt (compatible with Solr BasicAuth)
    hashed = hash_password_solr(password)

    # Output only the hash (no newline for easy scripting)
    print(hashed, end='')
