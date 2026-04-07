#!/bin/sh
# Instalador de FacturaDirecta CLI
# Uso: curl -fsSL https://raw.githubusercontent.com/facturadirecta/facturadirecta-cli/main/scripts/install.sh | sh
#
# Variables de entorno opcionales:
#   INSTALL_DIR    — directorio de instalación (default: ~/.local/bin)
#   VERSION        — versión específica (default: última)

set -e

REPO="facturadirecta/facturadirecta-cli"
BINARY="facturadirecta"
DEFAULT_INSTALL_DIR="$HOME/.local/bin"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"

# --- Detección de plataforma ---

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "darwin" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) error "Sistema operativo no soportado: $(uname -s)" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) error "Arquitectura no soportada: $(uname -m)" ;;
  esac
}

# --- Utilidades ---

info() { printf '\033[0;32m%s\033[0m\n' "$1"; }
warn() { printf '\033[0;33m%s\033[0m\n' "$1"; }
error() { printf '\033[0;31mError: %s\033[0m\n' "$1" >&2; exit 1; }

check_command() {
  command -v "$1" >/dev/null 2>&1
}

# --- Resolución de versión ---

resolve_version() {
  if [ -n "$VERSION" ]; then
    echo "$VERSION"
    return
  fi

  # Try gh CLI first (works with private repos)
  if check_command gh; then
    gh release view --repo "$REPO" --json tagName -q '.tagName' 2>/dev/null && return
  fi

  # Fallback to HTTP redirect for public repos
  if check_command curl; then
    curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" 2>/dev/null | grep -o 'v[0-9].*' || true
  elif check_command wget; then
    wget -q -O /dev/null --server-response "https://github.com/$REPO/releases/latest" 2>&1 | grep -o 'v[0-9][^ ]*' | tail -1 || true
  fi
}

# --- Descarga ---

download() {
  url="$1"
  dest="$2"
  if check_command curl; then
    curl -fsSL -o "$dest" "$url" 2>/dev/null && return
  fi
  if check_command wget; then
    wget -q -O "$dest" "$url" 2>/dev/null && return
  fi
  error "Se necesita curl o wget para la descarga"
}

# Download a release asset (uses gh for private repos, curl/wget for public)
download_release_asset() {
  version="$1"
  filename="$2"
  dest="$3"

  # Try gh first (handles private repos)
  if check_command gh; then
    gh release download "$version" --repo "$REPO" --pattern "$filename" --dir "$(dirname "$dest")" 2>/dev/null
    if [ -f "$(dirname "$dest")/$filename" ]; then
      mv "$(dirname "$dest")/$filename" "$dest" 2>/dev/null || true
      return
    fi
  fi

  # Fallback to direct download (public repos)
  download "https://github.com/$REPO/releases/download/$version/$filename" "$dest"
}

# --- Verificación de checksum ---

verify_checksum() {
  archive="$1"
  checksums_file="$2"
  archive_name="$(basename "$archive")"

  expected=$(grep "$archive_name" "$checksums_file" | awk '{print $1}')
  if [ -z "$expected" ]; then
    warn "No se encontró checksum para $archive_name, saltando verificación"
    return
  fi

  if check_command sha256sum; then
    actual=$(sha256sum "$archive" | awk '{print $1}')
  elif check_command shasum; then
    actual=$(shasum -a 256 "$archive" | awk '{print $1}')
  else
    warn "sha256sum/shasum no disponible, saltando verificación de checksum"
    return
  fi

  if [ "$expected" != "$actual" ]; then
    error "Checksum no coincide para $archive_name\n  Esperado: $expected\n  Obtenido: $actual"
  fi
}

# --- Instalación ---

main() {
  os=$(detect_os)
  arch=$(detect_arch)

  info "Detectado: ${os}/${arch}"

  version=$(resolve_version)
  if [ -z "$version" ]; then
    error "No se pudo determinar la última versión. Usa VERSION=v0.4.0 para especificar una."
  fi

  info "Instalando $BINARY $version..."

  # Determinar extensión y nombre del archivo
  ext="tar.gz"
  if [ "$os" = "windows" ]; then
    ext="zip"
  fi
  archive_name="${BINARY}-cli_${os}_${arch}.${ext}"
  base_url="https://github.com/$REPO/releases/download/$version"

  # Crear directorio temporal
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  # Descargar archivo y checksums
  info "Descargando ${archive_name}..."
  download_release_asset "$version" "$archive_name" "$tmp_dir/$archive_name"
  download_release_asset "$version" "checksums.txt" "$tmp_dir/checksums.txt"

  # Verificar checksum
  verify_checksum "$tmp_dir/$archive_name" "$tmp_dir/checksums.txt"
  info "Checksum verificado correctamente"

  # Extraer
  if [ "$ext" = "tar.gz" ]; then
    tar -xzf "$tmp_dir/$archive_name" -C "$tmp_dir"
  else
    unzip -q "$tmp_dir/$archive_name" -d "$tmp_dir"
  fi

  # Instalar
  mkdir -p "$INSTALL_DIR"
  mv "$tmp_dir/$BINARY" "$INSTALL_DIR/$BINARY"
  chmod +x "$INSTALL_DIR/$BINARY"

  info "$BINARY instalado en $INSTALL_DIR/$BINARY"

  # Verificar que está en PATH
  if ! echo "$PATH" | tr ':' '\n' | grep -q "^${INSTALL_DIR}$"; then
    warn ""
    warn "IMPORTANTE: $INSTALL_DIR no está en tu PATH."
    warn "Añade esta línea a tu ~/.bashrc, ~/.zshrc o equivalente:"
    warn ""
    warn "  export PATH=\"$INSTALL_DIR:\$PATH\""
    warn ""
  fi

  # Verificar instalación
  if "$INSTALL_DIR/$BINARY" --version >/dev/null 2>&1; then
    installed_version=$("$INSTALL_DIR/$BINARY" --version 2>&1 | awk '{print $NF}')
    info ""
    info "$BINARY $installed_version instalado correctamente."
    info ""
    info "Primeros pasos:"
    info "  $BINARY login              # Iniciar sesión"
    info "  $BINARY profile            # Ver empresas disponibles"
    info "  $BINARY invoices list      # Listar facturas"
  else
    error "La instalación falló. El binario no se ejecuta correctamente."
  fi
}

main
