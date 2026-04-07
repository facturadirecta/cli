# FacturaDirecta CLI

Herramienta de línea de comandos y servidor MCP para la [API de FacturaDirecta](https://www.facturadirecta.com) — software de facturación y contabilidad en la nube para autónomos y pymes en España.

## Instalación

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/facturadirecta/cli/main/install.sh | sh
```

### Windows

Descarga el archivo `.zip` de la [última release](https://github.com/facturadirecta/cli/releases/latest) y extrae `facturadirecta.exe` en una carpeta de tu PATH.

### Homebrew (macOS / Linux)

```bash
brew install facturadirecta/tap/facturadirecta
```

## Inicio rápido

```bash
facturadirecta setup                    # Configuración guiada (login + empresa + MCP)
```

O paso a paso:

```bash
facturadirecta login                    # Iniciar sesión (solo lectura por defecto)
facturadirecta login --scope full       # Acceso completo (lectura y escritura)
facturadirecta auth profile             # Ver empresas disponibles
facturadirecta auth use-company <id>    # Seleccionar empresa activa
```

## Uso

```bash
facturadirecta invoices list            # Listar facturas
facturadirecta contacts list            # Listar contactos
facturadirecta products list            # Listar productos
facturadirecta estimates list           # Listar presupuestos
facturadirecta --help                   # Ver todos los comandos
```

## Integración con Claude Desktop / Cursor (MCP)

El CLI incluye un servidor MCP para integración con asistentes de IA:

```bash
facturadirecta setup                    # Configura MCP automáticamente
# o manualmente:
facturadirecta mcp-config               # Muestra la configuración MCP
```

## Requisitos

- macOS, Linux o Windows (amd64 o arm64)
- No requiere Go ni ningún otro runtime — el binario es autocontenido

## Versiones

Consulta las [releases](https://github.com/facturadirecta/cli/releases) para ver todas las versiones disponibles.

## Soporte

Para reportar problemas o sugerencias, abre un [issue](https://github.com/facturadirecta/cli/issues).
