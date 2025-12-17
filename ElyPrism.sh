#!/bin/bash

# -------------------------
# Checar dependências
# -------------------------
check_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Dependência faltando: $1"
        exit 1
    }
}

for cmd in curl wget jq update-desktop-database; do
    check_command "$cmd"
done

# -------------------------
# Diretórios
# -------------------------
USER_HOME="$HOME"
ELY_DIR="$USER_HOME/ElyPrism"
APPIMAGE_FILE="$ELY_DIR/ElyPrismLauncher-Linux-x86_64.AppImage"
ICON_FILE="$ELY_DIR/icon.png"
DESKTOP_FILE="$USER_HOME/.local/share/applications/elyprism.desktop"

mkdir -p "$ELY_DIR"
mkdir -p "$(dirname "$DESKTOP_FILE")"

# -------------------------
# Buscar AppImage mais recente (API GitHub)
# -------------------------
echo "Buscando AppImage x86_64 mais recente..."

APPIMAGE_URL=$(curl -s https://api.github.com/repos/ElyPrismLauncher/ElyPrismLauncher/releases/latest \
  | jq -r '.assets[] | select(.name | test("Linux-x86_64.*AppImage$")) | .browser_download_url')

if [ -z "$APPIMAGE_URL" ]; then
    echo "Não foi possível encontrar o AppImage x86_64."
    exit 1
fi

echo "Baixando ElyPrismLauncher..."
wget -q --show-progress -O "$APPIMAGE_FILE" "$APPIMAGE_URL" || exit 1
chmod +x "$APPIMAGE_FILE"

# -------------------------
# Ícone
# -------------------------
echo "Baixando ícone..."
wget -q --show-progress -O "$ICON_FILE" \
"https://raw.githubusercontent.com/InoCity/ElyPrism-installer/main/icon.png" || exit 1

# -------------------------
# Criar .desktop
# -------------------------
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=ElyPrism Launcher
Exec=$APPIMAGE_FILE
Icon=$ICON_FILE
Type=Application
Categories=Game;Minecraft;
Terminal=false
EOF

# -------------------------
# Atualizar menu
# -------------------------
update-desktop-database "$USER_HOME/.local/share/applications/" 2>/dev/null

# -------------------------
# Executar
# -------------------------
read -p "Deseja executar o ElyPrism agora? (y/n) " RESP
if [[ "$RESP" =~ ^[Yy]$ ]]; then
    "$APPIMAGE_FILE" &
fi

echo "Instalação concluída! ElyPrism já aparece no menu."
