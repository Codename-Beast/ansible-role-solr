#!/usr/bin/env python3
"""
Solr Password Hashing Utility
Generates SHA-256 hashed passwords compatible with Solr BasicAuth
"""

import hashlib
import base64
import secrets
import sys
import argparse


def generate_salt(length=32):
    """Generate a random salt for password hashing"""
    return secrets.token_bytes(length)


def hash_password(password, salt=None):
    """
    Hash a password using SHA-256
    Returns base64-encoded hash in Solr-compatible format
    """
    if salt is None:
        salt = generate_salt()

    combined = salt + password.encode('utf-8')
    hashed = hashlib.sha256(combined).digest()

    salt_base64 = base64.b64encode(salt).decode('utf-8')
    hash_base64 = base64.b64encode(hashed).decode('utf-8')

    return f"IV0EHq1OnNrj6gvRCwvFwTrZ1+z1oDK3LXCp0KhlNNI= {hash_base64}"


def generate_security_config(admin_pass, support_pass, customer_pass):
    """Generate complete security.json configuration"""
    admin_hash = hash_password(admin_pass)
    support_hash = hash_password(support_pass)
    customer_hash = hash_password(customer_pass)

    return {
        "admin_hash": admin_hash,
        "support_hash": support_hash,
        "customer_hash": customer_hash
    }


def main():
    parser = argparse.ArgumentParser(description='Generate Solr password hashes')
    parser.add_argument('password', nargs='?', help='Password to hash')
    parser.add_argument('--admin', help='Admin password')
    parser.add_argument('--support', help='Support password')
    parser.add_argument('--customer', help='Customer password')
    parser.add_argument('--all', action='store_true', help='Generate all three passwords')

    args = parser.parse_args()

    if args.all:
        if not (args.admin and args.support and args.customer):
            print("Error: When using --all, provide --admin, --support, and --customer passwords")
            sys.exit(1)

        config = generate_security_config(args.admin, args.support, args.customer)
        print("\n=== Solr Password Hashes ===")
        print(f"\nAdmin:    {config['admin_hash']}")
        print(f"Support:  {config['support_hash']}")
        print(f"Customer: {config['customer_hash']}")
        print("\nCopy these hashes to your config/security.json file")

    elif args.password:
        hashed = hash_password(args.password)
        print(hashed)

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()
