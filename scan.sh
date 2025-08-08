#!/bin/bash

# ================================
# Permission Scanner & Fixer Universal
# ================================

# colorlib
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Header
show_header() {
    echo -e "${BLUE}=================================="
    echo -e "   ZUPPIT PERMISSION SCANNER & FIXER"
    echo -e "==================================${NC}"
}

# Scan function
scan_permissions() {
    local target_dir="$1"
    local issues_found=false

    echo -e "${YELLOW}[INFO] Starting scan on: ${target_dir}${NC}"
    echo

    declare -a problem_files
    declare -a problem_dirs

    # Scan files
    while IFS= read -r -d '' file; do
        perm=$(stat -c "%a" "$file" 2>/dev/null)
        if [[ "$perm" != "644" && "$perm" != "755" && "$perm" != "600" ]]; then
            problem_files+=("$file:$perm")
            echo -e "${RED}[ISSUE] File: $file (Permission: $perm)${NC}"
            issues_found=true
        fi
    done < <(find "$target_dir" -type f \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/vendor/*" \
        -not -path "*/__pycache__/*" -print0 2>/dev/null)

    # Scan folders
    while IFS= read -r -d '' dir; do
        perm=$(stat -c "%a" "$dir" 2>/dev/null)
        if [[ "$perm" != "755" && "$perm" != "750" ]]; then
            problem_dirs+=("$dir:$perm")
            echo -e "${RED}[ISSUE] Dir: $dir (Permission: $perm)${NC}"
            issues_found=true
        fi
    done < <(find "$target_dir" -type d \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/vendor/*" \
        -not -path "*/__pycache__/*" -print0 2>/dev/null)

    if [[ "$issues_found" == true ]]; then
        echo
        echo -e "${YELLOW}[SUMMARY] ${#problem_files[@]} problematic file(s) & ${#problem_dirs[@]} problematic folder(s)${NC}"
        return 1
    else
        echo -e "${GREEN}[SUMMARY] All permissions are correct${NC}"
        return 0
    fi
}

# Fix function
fix_permissions() {
    local target_dir="$1"
    echo -e "${YELLOW}[INFO] Fixing permissions...${NC}"

    # Folders 755
    find "$target_dir" -type d \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/vendor/*" \
        -not -path "*/__pycache__/*" -exec chmod 755 {} \; 2>/dev/null

    # Sensitive files 600
    find "$target_dir" -type f \( -name "*.key" -o -name "*.pem" -o -name ".env" -o -name ".htaccess" \) \
        -exec chmod 600 {} \; 2>/dev/null

    # Script files 755
    find "$target_dir" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" \) \
        -exec chmod 755 {} \; 2>/dev/null

    # Regular files 644
    find "$target_dir" -type f \
        ! \( -name "*.sh" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" -o -name "*.key" -o -name "*.pem" -o -name ".env" -o -name ".htaccess" \) \
        -exec chmod 644 {} \; 2>/dev/null

    echo -e "${GREEN}[SUCCESS] Permissions have been fixed successfully${NC}"
}

# Main
main() {
    show_header

    # Input target dir
    while true; do
        echo -ne "${BLUE}Enter target path:${NC} "
        read -r target_directory
        if [[ -z "$target_directory" ]]; then
            echo -e "${RED}[ERROR] Path cannot be empty${NC}"
            continue
        fi
        if [[ ! -d "$target_directory" ]]; then
            echo -e "${RED}[ERROR] Directory not found${NC}"
            continue
        fi
        break
    done

    echo
    echo -e "${YELLOW}=== INITIAL SCAN ===${NC}"
    if scan_permissions "$target_directory"; then
        echo -e "${GREEN}[RESULT] No permission issues found${NC}"
        exit 0
    fi

    echo
    echo -ne "${YELLOW}Fix permissions now? (y/n):${NC} "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[INFO] Fix cancelled${NC}"
        exit 0
    fi

    echo
    echo -e "${YELLOW}=== FIXING ===${NC}"
    fix_permissions "$target_directory"

    echo
    echo -e "${YELLOW}=== RE-SCANNING ===${NC}"
    scan_permissions "$target_directory"
}

trap 'echo -e "\n${YELLOW}[INFO] Stopped by user${NC}"; exit 1' INT
main
