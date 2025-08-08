#!/bin/bash

# ================================
# Permission Scanner & Fixer Universal
# ================================

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Header
show_header() {
    echo -e "${BLUE}=================================="
    echo -e "   PERMISSION SCANNER & FIXER"
    echo -e "==================================${NC}"
}

# Fungsi scan
scan_permissions() {
    local target_dir="$1"
    local issues_found=false

    echo -e "${YELLOW}[INFO] Memulai scan di: ${target_dir}${NC}"
    echo

    declare -a problem_files
    declare -a problem_dirs

    # Scan file
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

    # Scan folder
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
        echo -e "${YELLOW}[SUMMARY] ${#problem_files[@]} file & ${#problem_dirs[@]} folder bermasalah${NC}"
        return 1
    else
        echo -e "${GREEN}[SUMMARY] Semua permission sudah sesuai${NC}"
        return 0
    fi
}

# Fungsi fix
fix_permissions() {
    local target_dir="$1"
    echo -e "${YELLOW}[INFO] Memperbaiki permission...${NC}"

    # Folder 755
    find "$target_dir" -type d \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/vendor/*" \
        -not -path "*/__pycache__/*" -exec chmod 755 {} \; 2>/dev/null

    # File sensitif 600
    find "$target_dir" -type f \( -name "*.key" -o -name "*.pem" -o -name ".env" -o -name ".htaccess" \) \
        -exec chmod 600 {} \; 2>/dev/null

    # File script 755
    find "$target_dir" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" \) \
        -exec chmod 755 {} \; 2>/dev/null

    # File biasa 644
    find "$target_dir" -type f \
        ! \( -name "*.sh" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" -o -name "*.key" -o -name "*.pem" -o -name ".env" -o -name ".htaccess" \) \
        -exec chmod 644 {} \; 2>/dev/null

    echo -e "${GREEN}[SUCCESS] Permission berhasil diperbaiki${NC}"
}

# Main
main() {
    show_header

    # Input target dir
    while true; do
        echo -ne "${BLUE}Masukkan path target:${NC} "
        read -r target_directory
        if [[ -z "$target_directory" ]]; then
            echo -e "${RED}[ERROR] Path tidak boleh kosong${NC}"
            continue
        fi
        if [[ ! -d "$target_directory" ]]; then
            echo -e "${RED}[ERROR] Direktori tidak ditemukan${NC}"
            continue
        fi
        break
    done

    echo
    echo -e "${YELLOW}=== SCAN AWAL ===${NC}"
    if scan_permissions "$target_directory"; then
        echo -e "${GREEN}[RESULT] Tidak ada masalah permission${NC}"
        exit 0
    fi

    echo
    echo -ne "${YELLOW}Perbaiki permission sekarang? (y/n):${NC} "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[INFO] Perbaikan dibatalkan${NC}"
        exit 0
    fi

    echo
    echo -e "${YELLOW}=== FIXING ===${NC}"
    fix_permissions "$target_directory"

    echo
    echo -e "${YELLOW}=== SCAN ULANG ===${NC}"
    scan_permissions "$target_directory"
}

trap 'echo -e "\n${YELLOW}[INFO] Dihentikan user${NC}"; exit 1' INT
main
