#!/bin/bash

# -------------------------
# Função para checar dependências
# -------------------------
check_command() {
    command -v "$1" >/dev/null 2>&1 || { echo "Dependência faltando: $1. Instale antes de continuar."; exit 1; }
}

# Checar dependências necessárias
for cmd in wget curl update-desktop-database; do
    check_command "$cmd"
done

# gtk-update-icon-cache é opcional
if ! command -v gtk-update-icon-cache >/dev/null 2>&1; then
    echo "Aviso: gtk-update-icon-cache não encontrado. Atualização de ícones GTK pode falhar."
fi

# -------------------------
# Configura diretórios
# -------------------------
USER_HOME=$(eval echo "~$USER")
ELY_DIR="$USER_HOME/ElyPrism"
mkdir -p "$ELY_DIR" || { echo "Erro ao criar diretório $ELY_DIR"; exit 1; }

# -------------------------
# Baixar AppImage mais recente
# -------------------------
echo "Buscando URL do ElyPrismLauncher mais recente..."
APPIMAGE_PATH=$(curl -sL https://github.com/ElyPrismLauncher/ElyPrismLauncher/releases/latest \
    | grep -oP 'href="\K.*?ElyPrismLauncher-Linux-x86_64\.AppImage' | head -n 1)

if [ -z "$APPIMAGE_PATH" ]; then
    echo "Não foi possível encontrar o AppImage mais recente."
    exit 1
fi

APPIMAGE_URL="https://github.com$APPIMAGE_PATH"
APPIMAGE_FILE="$ELY_DIR/ElyPrismLauncher-Linux-x86_64.AppImage"

echo "Baixando ElyPrismLauncher..."
wget -q --show-progress -O "$APPIMAGE_FILE" "$APPIMAGE_URL" || { echo "Falha no download do AppImage"; exit 1; }

# -------------------------
# Baixar ícone
# -------------------------
echo "Baixando ícone..."
ICON_URL="https://raw.githubusercontent.com/InoCity/ElyPrism-installer/main/icon.png"
wget -q --show-progress -O "$ELY_DIR/icon.png" "$ICON_URL" || { echo "Falha no download do ícone"; exit 1; }

# -------------------------
# Criar arquivo .desktop
# -------------------------
DESKTOP_FILE="$USER_HOME/.local/share/applications/elyprism.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"

cat > "$DESKTOP_FILE" <<EOL
[Desktop Entry]
Name=ElyPrism
Exec=$APPIMAGE_FILE
Icon=$ELY_DIR/icon.png
Type=Application
Categories=Game;Minecraft;
Terminal=false
EOL

# -------------------------
# Detectar ambiente gráfico e protocolo
# -------------------------
DESKTOP_ENV=$(echo "${XDG_CURRENT_DESKTOP:-unknown}" | tr '[:upper:]' '[:lower:]')
DISPLAY_TYPE=$(echo "${XDG_SESSION_TYPE:-unknown}" | tr '[:upper:]' '[:lower:]')

echo "Ambiente gráfico detectado: $DESKTOP_ENV, Sessão: $DISPLAY_TYPE"

# -------------------------
# Atualizar caches
# -------------------------
echo "Atualizando banco de dados de aplicativos e cache de ícones..."
case "$DESKTOP_ENV" in
    kde*|plasma*)
        gtk-update-icon-cache "$HOME/.local/share/icons" 2>/dev/null
        update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null
        ;;
    gnome*|unity*)
        update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null
        ;;
    unknown|*)
        echo "Ambiente gráfico não detectado. Atualizando banco de aplicativos genericamente..."
        update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null
        ;;
esac

# Wayland ou X11
if [[ "$DISPLAY_TYPE" == "wayland" ]]; then
    echo "Sessão Wayland detectada."
elif [[ "$DISPLAY_TYPE" == "x11" ]]; then
    echo "Sessão X11 detectada."
else
    echo "Tipo de sessão desconhecido."
fi

# -------------------------
# Permissões e execução
# -------------------------
chmod +x "$APPIMAGE_FILE"

read -p "Deseja executar o ElyPrism agora? (y/n) " RESP
if [[ "$RESP" =~ ^[Yy]$ ]]; then
    "$APPIMAGE_FILE" &
fi

echo "Instalação concluída! ElyPrism deve aparecer no menu de aplicativos."
