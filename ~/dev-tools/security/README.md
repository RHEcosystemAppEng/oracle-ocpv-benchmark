# Personal Security Tools

This directory contains security tools for scanning and protecting your repositories across all projects.

## Setup

1. **Add to PATH**: The directory should be added to your PATH in `~/.zshrc`:
   ```bash
   export PATH="$HOME/dev-tools/security:$PATH"
   ```

2. **Source your shell**: Run `source ~/.zshrc` or restart your terminal.

## Tools

### 1. Local Scanner (`scan-sensitive-info.sh`)

**Usage:**
```bash
# Scan current repository
scan-sensitive-info.sh

# Scan specific files
scan-sensitive-info.sh file1.yml file2.md

# From any directory
cd /path/to/your/project
scan-sensitive-info.sh
```

**What it detects:**
- IP addresses (public and private)
- DNS hostnames
- Password fields
- Secret keys and tokens
- Private key files (.pem, .key, id_rsa, etc.)
- AWS credentials
- Database URLs
- Email addresses
- JWT tokens

### 2. GitHub Action (`github-action-security-scan.yml`)

**Usage in your workflow:**
```yaml
name: Security Check
on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Security Scan
        uses: ./.github/actions/security-scan
        with:
          fail-on-detection: false  # or true to fail the build
          exclude-files: 'package-lock.json,yarn.lock'
```

**To use across multiple repositories:**
1. Create a separate repository for your GitHub actions
2. Move `github-action-security-scan.yml` to that repository
3. Reference it in your workflows: `uses: your-username/security-actions/.github/actions/security-scan@main`

### 3. Pre-commit Hook Integration

Each project repository can have a pre-commit hook that uses the global scanner:

```bash
# In .git/hooks/pre-commit
~/dev-tools/security/scan-sensitive-info.sh
```

## Safe Patterns

The scanner allows these patterns (won't flag them):
- `127.0.0.1`, `localhost`, `0.0.0.0`, `255.255.255.255`
- `example.com`
- Placeholders: `<your-ip>`, `{{ ansible_host }}`, `${VARIABLE}`
- Generic words: `password`, `secret`, `token` (when used as placeholders)

## Customization

To add more patterns or safe patterns, edit the `PATTERNS` and `SAFE_PATTERNS` arrays in the scripts.

## Best Practices

1. **Use placeholders**: Replace sensitive data with `<your-ip-address>`, `<your-hostname>`
2. **Environment variables**: Use `${ORACLE_PASSWORD}` instead of hardcoded passwords
3. **Templates**: Use `{{ ansible_host }}` for templated configurations
4. **Gitignore**: Add sensitive files to `.gitignore`
5. **Encryption**: Use `ansible-vault` for secrets in Ansible projects 