#!/usr/bin/env python3
"""
Solr Password Hashing Utility
Generates SHA-256 hashed passwords compatible with Solr BasicAuth

Version: 2.3.0
Changes: Made password hashing deterministic and idempotent
"""

import hashlib
import base64
import sys
import os
import argparse


def generate_deterministic_salt(password, seed=None):
    """
    Generate a deterministic salt from password and optional seed.
    This ensures idempotent hashing - same password + seed = same hash

    Args:
        password: The password to hash
        seed: Optional seed (e.g., CUSTOMER_NAME). Uses hostname if not provided.

    Returns:
        bytes: 32-byte deterministic salt
    """
    if seed is None:
        seed = os.environ.get('CUSTOMER_NAME', 'solr-default-seed')

    # Create deterministic salt using PBKDF2
    salt_source = f"{seed}:solr-auth:{password}".encode('utf-8')
    deterministic_salt = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt_source, 10000, dklen=32)

    return deterministic_salt


def hash_password(password, salt=None, seed=None):
    """
    Hash a password using SHA-256 with deterministic salt.
    Returns base64-encoded hash in Solr-compatible format.

    Args:
        password: The password to hash
        salt: Optional salt (bytes). If None, generates deterministic salt.
        seed: Optional seed for deterministic salt generation

    Returns:
        str: Solr-compatible password hash in format "SALT HASH"
    """
    if salt is None:
        salt = generate_deterministic_salt(password, seed)

    # Combine salt and password, then hash
    combined = salt + password.encode('utf-8')
    hashed = hashlib.sha256(combined).digest()

    # Encode to base64
    salt_base64 = base64.b64encode(salt).decode('utf-8')
    hash_base64 = base64.b64encode(hashed).decode('utf-8')

    return f"{salt_base64} {hash_base64}"


def generate_security_config(admin_pass, support_pass, customer_pass, seed=None):
    """
    Generate complete security.json configuration

    Args:
        admin_pass: Admin user password
        support_pass: Support user password
        customer_pass: Customer user password
        seed: Optional seed for deterministic hashing

    Returns:
        dict: Password hashes for all three users
    """
    admin_hash = hash_password(admin_pass, seed=seed)
    support_hash = hash_password(support_pass, seed=seed)
    customer_hash = hash_password(customer_pass, seed=seed)

    return {
        "admin_hash": admin_hash,
        "support_hash": support_hash,
        "customer_hash": customer_hash
    }


def main():
    parser = argparse.ArgumentParser(
        description='Generate Solr password hashes (deterministic)',
        epilog='Hashes are idempotent: same password + seed = same hash'
    )
    parser.add_argument('password', nargs='?', help='Password to hash')
    parser.add_argument('--seed', help='Seed for deterministic hashing (default: $CUSTOMER_NAME)')
    parser.add_argument('--admin', help='Admin password')
    parser.add_argument('--support', help='Support password')
    parser.add_argument('--customer', help='Customer password')
    parser.add_argument('--all', action='store_true', help='Generate all three passwords')
    parser.add_argument('--verify', nargs=2, metavar=('PASSWORD', 'HASH'),
                        help='Verify a password against a hash')

    args = parser.parse_args()

    seed = args.seed or os.environ.get('CUSTOMER_NAME')

    if args.verify:
        password, expected_hash = args.verify
        actual_hash = hash_password(password, seed=seed)
        if actual_hash == expected_hash:
            print("✓ Password matches hash")
            sys.exit(0)
        else:
            print("✗ Password does NOT match hash")
            print(f"Expected: {expected_hash}")
            print(f"Got:      {actual_hash}")
            sys.exit(1)

    elif args.all:
        if not (args.admin and args.support and args.customer):
            print("Error: When using --all, provide --admin, --support, and --customer passwords")
            sys.exit(1)

        config = generate_security_config(args.admin, args.support, args.customer, seed=seed)
        print("\n=== Solr Password Hashes (Deterministic) ===")
        if seed:
            print(f"Seed: {seed}")
        print(f"\nAdmin:    {config['admin_hash']}")
        print(f"Support:  {config['support_hash']}")
        print(f"Customer: {config['customer_hash']}")
        print("\nCopy these hashes to your config/security.json file")
        print("\n✓ These hashes are idempotent - re-running with same passwords will produce same hashes")

    elif args.password:
        hashed = hash_password(args.password, seed=seed)
        print(hashed)

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()
