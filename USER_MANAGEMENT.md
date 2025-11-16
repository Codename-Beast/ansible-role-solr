# Solr User Management Guide

## Overview

This role supports two modes of user management:
1. **Deploy Mode**: Users are created during initial deployment (requires container restart)
2. **Live Mode**: Users are added on-the-fly via API (NO downtime, NO restart)

## Adding Users

### 1. Define Users in Inventory

Add users to your `host_vars/<hostname>.yml` or group_vars:

```yaml
solr_additional_users:
  - username: "tenant1_admin"
    password: "SecurePassword123!"
    roles: ["core-admin-tenant1_core"]  # Optional

  - username: "tenant2_readonly"
    password: "AnotherSecure456!"
    roles: ["support"]  # Optional

  - username: "api_user"
    password: "ApiKey789!"
    # If roles omitted, defaults to ["core-admin-<core_name>"]
```

### 2. User Roles

Available roles:
- `admin` - Full admin access to all Solr endpoints
- `support` - Read-only access (GET, HEAD)
- `moodle` - Read/Write access for Moodle plugin (GET, HEAD, POST, DELETE)
- `core-admin-<core_name>` - Full access to specific core

### 3. Deploy Users

#### Option A: During Initial Deployment

```bash
ansible-playbook install-solr.yml --tags=install-solr-users
```

This includes user creation in the full deployment process.

#### Option B: Hot-Reload Update (ZERO DOWNTIME) ⚡

```bash
ansible-playbook install-solr.yml --tags=solr-auth-reload
# OR
ansible-playbook install-solr.yml --tags=solr-users-hotupdate
```

This updates users via Solr API without container restart!

**Use cases:**
- Adding new tenant users
- Changing user passwords
- Updating user roles
- Emergency user access grants

**Requirements:**
- Solr container must be running
- At least one admin user must exist
- `solr_admin_user` and `solr_admin_password` must be defined

## Tag Reference

| Tag | Description | Downtime? |
|-----|-------------|-----------|
| `install-solr-users` | Deploy users during installation | Yes (restart) |
| `solr-users-deploy` | Deploy users with config generation | Yes (restart) |
| `solr-auth-reload` | Hot-reload users via API (zero-downtime) | **No** ⚡ |
| `solr-users-hotupdate` | Alias for solr-auth-reload | **No** ⚡ |

## Examples

### Example 1: Add New Tenant User (Live)

1. Edit `host_vars/myserver.yml`:
```yaml
solr_additional_users:
  - username: "tenant_xyz"
    password: "TenantXYZ2024!"
    roles: ["core-admin-tenant_xyz_core"]
```

2. Apply changes:
```bash
ansible-playbook install-solr.yml --tags=solr-auth-reload --limit=myserver
```

3. Verify:
```bash
curl -u tenant_xyz:TenantXYZ2024! http://localhost:8983/solr/admin/ping
```

### Example 2: Update Existing User Password (Hot-Reload)

1. Change password in `host_vars/myserver.yml`
2. Run: `ansible-playbook install-solr.yml --tags=solr-auth-reload`
3. User can immediately login with new password (zero-downtime!)

### Example 3: Bulk User Import

```yaml
solr_additional_users:
  - { username: "tenant1", password: "Pass1!", roles: ["core-admin-tenant1_core"] }
  - { username: "tenant2", password: "Pass2!", roles: ["core-admin-tenant2_core"] }
  - { username: "tenant3", password: "Pass3!", roles: ["core-admin-tenant3_core"] }
  - { username: "readonly", password: "Pass4!", roles: ["support"] }
```

## Security Best Practices

1. **Strong Passwords**: Minimum 16 characters, mix of uppercase, lowercase, numbers, symbols
2. **Role Isolation**: Use per-core roles for multi-tenancy
3. **Audit**: Monitor `solr_gc.log` for authentication attempts
4. **Rotation**: Regularly rotate passwords using `solr-auth-reload` tag
5. **Secrets Management**: Use Ansible Vault for password storage:

```bash
ansible-vault encrypt_string 'MySecurePassword123!' --name 'solr_moodle_password'
```

## Troubleshooting

### Issue: "User already exists"
**Solution**: This is normal - Solr API updates existing users when called twice.

### Issue: "Authentication failed after live update"
**Solution**: Check if user hash was generated correctly. Re-run with `-vvv` for debug output.

### Issue: "Container not running"
**Solution**: Hot-reload updates require running container. Use `solr-users-deploy` for initial setup.

## Technical Details

### Password Hashing

Passwords are hashed using double SHA256 with random salt:
```
hash = SHA256(SHA256(salt + password))
final = salt + " " + hash
```

This matches Solr's BasicAuthPlugin format.

### API Endpoints Used

- `POST /solr/admin/authentication` - Add/update users
- `GET /solr/admin/ping` - Verify authentication

### Files Modified

- `/var/solr/data/security.json` - User credentials and roles
- `{{ solr_config_dir }}/security.json` - Template source (host)

## Advanced Usage

### Custom Role Definitions

Define custom roles in `security.json.j2` template:

```json
{
  "name": "custom-role-name",
  "collection": "my_core",
  "path": ["/select", "/update"],
  "method": ["GET", "POST"],
  "role": ["custom_role"]
}
```

Then assign to users:
```yaml
solr_additional_users:
  - username: "custom_user"
    password: "password"
    roles: ["custom_role"]
```

## Monitoring

Check user activity in Solr logs:
```bash
docker logs {{ solr_container_name }} | grep -i "authentication"
```

## Support

For issues, check:
1. Container logs: `docker logs <container>`
2. Security.json syntax: `jq . /var/solr/data/security.json`
3. Ansible verbose output: `ansible-playbook ... -vvv`
