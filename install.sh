#!/bin/bash

set -e  # Bei Fehler abbrechen

# Prüfen ob stow installiert ist
if ! command -v stow &> /dev/null; then
    echo -e "${RED}✗${NC} stow not installed!"
    exit 1
fi

# Farben für Output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Font-Installation ===${NC}\n"

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
echo -e "${GREEN}✓${NC} Font-Verzeichnis: $FONT_DIR"

FONT_COUNT=$(find . -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.TTF" -o -name "*.OTF" \) | wc -l)

if [ "$FONT_COUNT" -eq 0 ]; then
    echo -e "${RED}✗${NC} no fonts found (.ttf/.otf) gefunden!"
    exit 1
fi

echo -e "${BLUE}→${NC} $FONT_COUNT Fonts found"
echo -e "${BLUE}→${NC} Copy fonts..."

cd fonts
find . -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.TTF" -o -name "*.OTF" \) -exec cp -v {} "$FONT_DIR/" \;

echo -e "\n${BLUE}→${NC} Aktualisiere Font-Cache..."
fc-cache -fv > /dev/null 2>&1

echo -e "\n${GREEN}Installation finished!${NC}"
echo -e "${GREEN}${NC} $FONT_COUNT fonts installed"
cd ..

# Automatically find all directories (excluding fonts and hidden dirs)
PROGRAMS=()
while IFS= read -r dir; do
    dirname=$(basename "$dir")
    # Skip fonts directory
    if [[ "$dirname" != "fonts" ]]; then
        PROGRAMS+=("$dirname")
    fi
done < <(find . -maxdepth 1 -type d ! -name "." ! -name "..*" | sort)

if [ ${#PROGRAMS[@]} -eq 0 ]; then
    echo -e "${RED}✗${NC} No directories found to stow!"
    exit 1
fi

echo -e "${BLUE}Found directories:${NC} ${PROGRAMS[*]}\n"

# Function to stow packages
stow_package() {
    local package=$1
    
    if [ ! -d "$package" ]; then
        echo -e "${YELLOW}⚠${NC}  Directory '$package' not found, skipping..."
        return
    fi
    
    echo -e "${BLUE}→${NC} Stowing $package..."
    if stow -v "$package" 2>&1; then
        echo -e "${GREEN}✓${NC} $package successfully symlinked"
    else
        echo -e "${RED}✗${NC} Error stowing $package"
    fi
}

# Ask for each program
for program in "${PROGRAMS[@]}"; do
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check if directory exists
    if [ ! -d "$program" ]; then
        echo -e "${YELLOW}⚠${NC}  $program: Directory not found"
        continue
    fi
    
    read -p "$(echo -e ${YELLOW}?${NC}) Stow $program? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        stow_package "$program"
    else
        echo -e "${BLUE}→${NC} $program skipped"
    fi
done

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Done!${NC}\n"

# Optional summary
echo -e "${BLUE}Tip:${NC} To remove later, use: ${YELLOW}stow -D <package>${NC}"

