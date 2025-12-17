#!/bin/bash
set -euo pipefail

# =====================
# Visual simples
# =====================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✔ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
err()  { echo -e "${RED}✖ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}➜ $1${NC}"; }

# =====================
# Arquitetura
# =====================
[ "$(uname -m)" = "x86_64" ] || err "Arquitetura não suportada"

# =====================
# Dependências
# =====================
DEPS=(curl jq pv update-desktop-database)
missing=()

for d in "${DEPS[@]}"; do
    command -v "$d" &>/dev/null || missing+=("$d")
done

if [ "${#missing[@]}" -ne 0 ]; then
    warn "Dependências faltando: ${missing[*]}"
    echo -e "${BLUE}🔐 Digite sua senha para instalar automaticamente:${NC}"
    sudo -v || err "Senha incorreta"
    sudo dnf install -y curl jq pv desktop-file-utils >/dev/null 2>&1
    ok "Dependências instaladas"
else
    ok "Dependências OK"
fi

# =====================
# Diretórios
# =====================
ELY_DIR="$HOME/ElyPrism"
APPIMAGE="$ELY_DIR/ElyPrismLauncher-Linux-x86_64.AppImage"
ICON="$ELY_DIR/icon.png"
DESKTOP="$HOME/.local/share/applications/elyprism.desktop"

mkdir -p "$ELY_DIR" "$(dirname "$DESKTOP")"

# =====================
# Buscar release
# =====================
info "Buscando versão mais recente"

URL=$(curl -s https://api.github.com/repos/ElyPrismLauncher/ElyPrismLauncher/releases/latest \
 | jq -r '.assets[] | select(.name | test("Linux-x86_64.*AppImage$")) | .browser_download_url')

[ -n "$URL" ] || err "AppImage não encontrado"
ok "Release encontrada"

# =====================
# Download (barra limpa)
# =====================
info "Baixando ElyPrismLauncher"

curl -L "$URL" -s \
| pv -p -t -e -r \
> "$APPIMAGE"

chmod +x "$APPIMAGE"
ok "Download concluído"

# =====================
# Ícone
# =====================
curl -sL \
"https://raw.githubusercontent.com/InoCity/ElyPrism-installer/main/icon.png" \
-o "$ICON" 2>/dev/null || warn "Ícone não baixado"

# =====================
# .desktop
# =====================
cat > "$DESKTOP" <<EOF
[Desktop Entry]
Name=ElyPrism Launcher
Exec=$APPIMAGE
Icon=$ICON
Type=Application
Categories=Game;Minecraft;
Terminal=false
StartupWMClass=elyprism
EOF

update-desktop-database "$HOME/.local/share/applications/" >/dev/null 2>&1
ok "Atalho criado no menu"

# =====================
# Final
# =====================
echo
ok "Instalação concluída 🎉"
read -p "Deseja executar agora? (y/n) " r
[[ "$r" =~ ^[Yy]$ ]] && "$APPIMAGE" &
