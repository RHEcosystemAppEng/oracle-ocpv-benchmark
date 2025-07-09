#!/bin/bash

# Standalone script to scan for sensitive information
# Can be run manually: ./scripts/scan-sensitive-info.sh
# Or on specific files: ./scripts/scan-sensitive-info.sh file1.yml file2.md

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Oracle OCPV Benchmark - Sensitive Information Scanner${NC}"
echo "=================================================="

# Define sensitive patterns
declare -A PATTERNS=(
    ["IP_ADDRESS"]="(?:[0-9]{1,3}\.){3}[0-9]{1,3}"
    ["IPV6_ADDRESS"]="([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}"
    ["PRIVATE_IP"]="(10\.([0-9]{1,3}\.){2}[0-9]{1,3})|(172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3})|(192\.168\.[0-9]{1,3}\.[0-9]{1,3})"
    ["DNS_HOSTNAME"]="[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)+"
    ["PASSWORD_FIELD"]="password\s*[:=]\s*['\"]?[^'\"\s<>]{3,}['\"]?"
    ["SECRET_KEY"]="(secret|key|token|auth)\s*[:=]\s*['\"]?[A-Za-z0-9+/]{10,}['\"]?"
    ["PRIVATE_KEY_FILE"]="\.pem|\.key|\.p12|\.pfx|id_rsa|id_dsa|id_ecdsa|id_ed25519"
    ["AWS_ACCESS_KEY"]="AKIA[0-9A-Z]{16}"
    ["AWS_SECRET_KEY"]="[0-9a-zA-Z/+]{40}"
    ["DATABASE_URL"]="(mysql|postgresql|mongodb|redis)://[^'\"\s<>]+"
    ["EMAIL_ADDRESS"]="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
    ["JWT_TOKEN"]="eyJ[A-Za-z0-9_/+=-]+"
    ["DOCKER_IMAGE"]="[a-zA-Z0-9][a-zA-Z0-9_.-]*\.[a-zA-Z0-9][a-zA-Z0-9_.-]*[:/][a-zA-Z0-9_.-]+"
    ["ORACLE_SID"]="(sid|service_name)\s*[:=]\s*['\"]?[A-Za-z0-9_]+['\"]?"
)

# Allow list for known safe patterns (customize as needed)
declare -A ALLOWLIST=(
    ["SAFE_IPS"]="127\.0\.0\.1|localhost|0\.0\.0\.0|255\.255\.255\.255"
    ["SAFE_DOMAINS"]="example\.com|localhost|127\.0\.0\.1"
    ["SAFE_PASSWORDS"]="password|secret|token|key|auth"  # Generic placeholders
    ["PLACEHOLDER_PATTERNS"]="<[^>]*>|\{\{[^}]*\}\}|\$\{[^}]*\}|YOUR_[A-Z_]+|REPLACE_[A-Z_]+"
    ["ORACLE_PLACEHOLDERS"]="pdb1|orcl|xe|sid|service_name"
)

VIOLATIONS_FOUND=0
TOTAL_FILES=0

# Function to check if a match is in allowlist
is_allowed() {
    local match="$1"
    local category="$2"
    
    # Check placeholder patterns first
    if echo "$match" | grep -qE "${ALLOWLIST[PLACEHOLDER_PATTERNS]}"; then
        return 0
    fi
    
    # Check category-specific allowlist
    case $category in
        "IP_ADDRESS"|"PRIVATE_IP")
            echo "$match" | grep -qE "${ALLOWLIST[SAFE_IPS]}"
            ;;
        "DNS_HOSTNAME")
            echo "$match" | grep -qE "${ALLOWLIST[SAFE_DOMAINS]}"
            ;;
        "PASSWORD_FIELD"|"SECRET_KEY")
            echo "$match" | grep -qiE "${ALLOWLIST[SAFE_PASSWORDS]}"
            ;;
        "ORACLE_SID")
            echo "$match" | grep -qiE "${ALLOWLIST[ORACLE_PLACEHOLDERS]}"
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to scan a file for sensitive patterns
scan_file() {
    local file="$1"
    local file_violations=0
    
    # Skip binary files
    if ! file "$file" | grep -q "text"; then
        return 0
    fi
    
    # Skip files that are typically safe
    case "$file" in
        *.log|*.tmp|*~|*.swp|*.bak) return 0 ;;
        .git/*) return 0 ;;
        node_modules/*) return 0 ;;
    esac
    
    echo "📄 Scanning: $file"
    
    for pattern_name in "${!PATTERNS[@]}"; do
        pattern="${PATTERNS[$pattern_name]}"
        
        # Use grep for pattern matching
        matches=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
        
        if [ -n "$matches" ]; then
            while IFS= read -r line; do
                line_num=$(echo "$line" | cut -d: -f1)
                content=$(echo "$line" | cut -d: -f2-)
                
                # Extract the actual match
                match=$(echo "$content" | grep -oE "$pattern" | head -1)
                
                # Check if this match is allowed
                if ! is_allowed "$match" "$pattern_name"; then
                    echo -e "${RED}❌ $pattern_name found in $file:$line_num${NC}"
                    echo -e "   Match: ${YELLOW}$match${NC}"
                    echo -e "   Context: $(echo "$content" | sed 's/^[[:space:]]*//')"
                    echo ""
                    file_violations=$((file_violations + 1))
                fi
            done <<< "$matches"
        fi
    done
    
    return $file_violations
}

# Determine files to scan
if [ $# -eq 0 ]; then
    echo "Scanning all tracked files..."
    FILES=$(git ls-files | grep -E '\.(yml|yaml|md|txt|sh|py|js|json|xml|properties|conf|cfg|ini)$')
else
    FILES="$@"
fi

# Skip if no files to check
if [ -z "$FILES" ]; then
    echo -e "${GREEN}✅ No files to scan${NC}"
    exit 0
fi

echo "Files to scan:"
echo "$FILES" | while read -r file; do
    echo "  - $file"
done
echo "----------------------------------------"

# Scan all files
for file in $FILES; do
    if [ -f "$file" ]; then
        TOTAL_FILES=$((TOTAL_FILES + 1))
        scan_file "$file"
        if [ $? -gt 0 ]; then
            VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
        fi
    fi
done

echo "----------------------------------------"
echo -e "${BLUE}Scan Summary:${NC}"
echo "Files scanned: $TOTAL_FILES"
echo "Files with violations: $VIOLATIONS_FOUND"

if [ $VIOLATIONS_FOUND -gt 0 ]; then
    echo -e "${RED}🚨 SECURITY ALERT: $VIOLATIONS_FOUND file(s) contain sensitive information!${NC}"
    echo ""
    echo -e "${YELLOW}Recommended actions:${NC}"
    echo "1. Replace sensitive data with placeholders like: <your-ip-address>"
    echo "2. Use environment variables: \${ORACLE_PASSWORD}"
    echo "3. Use configuration templates: {{ ansible_host }}"
    echo "4. Add sensitive files to .gitignore"
    echo "5. Consider using ansible-vault for sensitive data"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ No sensitive information detected. All clear!${NC}"
    exit 0
fi 