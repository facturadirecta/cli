<!-- Este README se publica con cada versión del CLI: los cambios que se hagan aquí se pierden en la siguiente. -->

# FacturaDirecta CLI

CLI para la API pública de [FacturaDirecta](https://www.facturadirecta.com), software de facturación y contabilidad en la nube.

> ¿Buscas la integración con Claude, ChatGPT, Cursor u otros asistentes de IA? Usa el servidor MCP oficial en `https://mcp.facturadirecta.com` (basta con la URL).

## Instalación

### Instalación rápida (macOS/Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/facturadirecta/cli/main/install.sh | sh
```

Detecta tu plataforma, descarga el binario, verifica el checksum SHA-256 y lo instala en `~/.local/bin`.

### Descarga directa

Descarga el binario para tu plataforma desde [GitHub Releases](https://github.com/facturadirecta/cli/releases):

| Plataforma | Archivo |
|---|---|
| macOS (Apple Silicon) | `facturadirecta-cli_darwin_arm64.tar.gz` |
| macOS (Intel) | `facturadirecta-cli_darwin_amd64.tar.gz` |
| Linux (x64) | `facturadirecta-cli_linux_amd64.tar.gz` |
| Linux (ARM) | `facturadirecta-cli_linux_arm64.tar.gz` |
| Windows (x64) | `facturadirecta-cli_windows_amd64.zip` |

También disponible como `.deb` y `.rpm` para Linux.

## Inicio rápido

Para configurar autenticación y seleccionar empresa de forma guiada:

```bash
facturadirecta setup
```

## Autenticación

### OAuth2 (recomendado)

Inicia sesión con tu cuenta de FacturaDirecta. Se abrirá el navegador para autenticarte y el CLI recibirá la respuesta en un puerto local libre:

```bash
facturadirecta login                  # Solo lectura (por defecto)
facturadirecta login --scope full     # Acceso completo (lectura y escritura)
facturadirecta login --no-browser     # Imprime la URL para abrirla a mano
facturadirecta login --port 31337     # Fija el puerto del callback (por defecto, uno libre)
```

Sin navegador en esta máquina (SSH, contenedores, agentes sin escritorio), usa el inicio de sesión por dispositivo: el CLI muestra una URL y un código para autorizarlo desde cualquier otro dispositivo, incluido el móvil:

```bash
facturadirecta login --device
facturadirecta login --device --scope full
```

El modo de solo lectura es el predeterminado. Usa `--scope full` únicamente
cuando necesites modificar datos. Los permisos que se piden salen del contrato
de la API: un recurso nuevo pide el suyo sin actualizar el CLI.

### Empresas y permisos del CLI

Tras identificarte, el CLI abre una segunda página de FacturaDirecta donde
eliges **a qué empresas accede el CLI y con qué permisos** en cada área
(lectura o completo). El CLI espera a que lo confirmes y guarda esa conexión en
el perfil: desde entonces solo ve esas empresas, con esos permisos. Con
`--device` o `--no-browser`, la URL solo se imprime para abrirla a mano.

```bash
facturadirecta auth permissions               # Abre la página para cambiar empresas y permisos
facturadirecta auth permissions --no-browser  # Solo imprime la URL
```

Los cambios se aplican al momento, sin volver a iniciar sesión. El techo son
los permisos de la sesión: con el login de solo lectura, la conexión no puede
escribir. Hay una conexión por perfil y máquina (`<perfil>@<máquina>`): volver a
iniciar sesión con el mismo perfil la sustituye, y `facturadirecta logout` la
revoca (si no puede, avisa y cierra la sesión igualmente). También puedes
revocarla desde FacturaDirecta.

Si cancelas en el navegador o la solicitud caduca (unos 30 minutos), el login
falla sin guardar nada: el perfil anterior, si lo había, queda como estaba. Si
el servidor aún no admite elegir empresas y permisos, el CLI avisa y sigue sin
conexión.

El CLI inicia sesión con su propio cliente OAuth, `facturadirecta-cli`, con el
que la API exige la conexión: un token del CLI sin ella no sirve. Para saltarte
este paso y acceder a todas tus empresas con los permisos de tu rol, usa
`--no-connection`, que inicia sesión con el cliente `facturadirecta-api` (el
único con el que la API admite peticiones sin conexión):

```bash
facturadirecta login --no-connection
```

Los perfiles guardados antes de este cambio siguen funcionando con
`facturadirecta-api` hasta que vuelvas a iniciar sesión.

### API Key

Alternativamente, usa una API Key generada desde Ajustes > API e integraciones:

```bash
facturadirecta login --api-key <tu-api-key> --company <companyId>               # Solo lectura
facturadirecta login --api-key <tu-api-key> --company <companyId> --scope full  # Acceso completo
```

Una API key es de una única empresa y no tiene usuario (ni paso de
conexión): `whoami` y `auth profile` muestran la empresa de la clave y los
scopes que la API le reconoce, y avisan si la clave ya no es válida. Para
trabajar con otra empresa, inicia sesión con su clave (en otro perfil, si
quieres conservar ambas).

## Configuración

Después de autenticarte, comprueba quién eres y qué empresa usarán los comandos:

```bash
facturadirecta whoami                          # Usuario, acceso, conexión, empresa resuelta y empresas disponibles
facturadirecta auth use-company <companyId>    # Fijar la empresa por defecto del perfil
facturadirecta auth status                     # Ver estado de la sesión (modo de acceso y conexión)
facturadirecta auth profile                    # Empresas disponibles y permisos de la conexión en cada una
```

`whoami` muestra también la conexión y los permisos de la conexión en cada
empresa. Con `--json` (o `-q`), pensado para agentes, devuelve `connection`
(`id`, `clientName` y `manageUrl`; nunca el secreto) y, en cada empresa de
`companies`, `permissions` (área → `read`, `full`…) y `manageUrl`. Sin
conexión (`--no-connection`, perfiles anteriores o API key), esos campos no
aparecen.

Cada comando resuelve la empresa en este orden: `--company` > variable de
entorno `FACTURADIRECTA_COMPANY` > empresa fijada en el perfil > la única
empresa del usuario. Con varias empresas y ninguna fijada, el error lista las
disponibles.

Para cambiar de modo, basta con volver a hacer login:

```bash
facturadirecta login                  # Cambia a solo lectura
facturadirecta login --scope full     # Cambia a acceso completo
```

## Uso

### Facturas

```bash
facturadirecta invoices list                           # Listar facturas
facturadirecta invoices list --state paid              # Filtrar por estado
facturadirecta invoices list --min-date 2025-01-01     # Filtrar por fecha
facturadirecta invoices list --state overdue --totals  # Con la suma de todas las filtradas (cuántas y cuánto suman)
facturadirecta invoices get <uuid>                     # Detalle de una factura
facturadirecta invoices create --data '{"content":{"type":"invoice","main":{...}}}' # Crear factura
facturadirecta invoices pdf <uuid>                     # Generar PDF
facturadirecta invoices send <uuid> --data '{"to":["cliente@example.com"]}' # Enviar por email
```

Los cuerpos de escritura siguen el contrato de la API: en altas y modificaciones,
`{"content": {"type": "<tipo>", "main": {...}}}`. `update` sustituye el contenido
completo (las líneas y los campos opcionales que no envíes se pierden): parte de
lo que devuelve `get`. Los cuerpos de cada operación, con ejemplos, están en la
[documentación de la API](https://github.com/facturadirecta/api-docs).

### Contactos

```bash
facturadirecta contacts list                    # Listar contactos
facturadirecta contacts list --search "Acme"    # Buscar por nombre
facturadirecta contacts get <uuid>              # Detalle
facturadirecta contacts create --data '{...}'   # Crear
facturadirecta contacts update <uuid> --data '{...}'  # Actualizar
facturadirecta contacts delete <uuid>           # Eliminar
```

### Productos

```bash
facturadirecta products list
facturadirecta products get <uuid>
facturadirecta products create --data '{...}'
facturadirecta products update <uuid> --data '{...}'
facturadirecta products delete <uuid>
```

### Presupuestos

```bash
facturadirecta estimates list
facturadirecta estimates get <uuid>
facturadirecta estimates create --data '{...}'
facturadirecta estimates send <uuid> --data '{...}'
facturadirecta estimates pdf <uuid>
```

### Albaranes

```bash
facturadirecta delivery-notes list
facturadirecta delivery-notes get <uuid>
facturadirecta delivery-notes create --data '{...}'
facturadirecta delivery-notes send <uuid> --data '{...}'
facturadirecta delivery-notes pdf <uuid>
```

### Gastos (facturas de compra)

```bash
facturadirecta bills list
facturadirecta bills list --state pending --totals     # Con la suma de todas las filtradas
facturadirecta bills get <uuid>
```

### Nóminas

```bash
facturadirecta payrolls list
facturadirecta payrolls get <uuid>
facturadirecta payrolls create --data '{...}'
facturadirecta payrolls pay <uuid> --data '{...}'
```

### Facturas recurrentes

```bash
facturadirecta recurring list
facturadirecta recurring get <uuid>
facturadirecta recurring create --data '{...}'
```

### Búsqueda

Una sola llamada que combina contactos (nombre, NIF, email), productos (nombre), facturas y presupuestos por número, y los últimos documentos de los contactos encontrados. No busca en el texto de las líneas ni en las notas: para eso, `--search` en los listados de documentos (`invoices list --search "hosting"`):

```bash
facturadirecta search "Acme"                        # Resultados con id tipo:empresa:id y URL
facturadirecta search "FAC-2026-12" --type invoice  # Por número; --type acota (invoice, estimate, bill, contact, product)
facturadirecta fetch invoice:com_xxx:inv_xxx        # Detalle legible; con -j el objeto completo
```

### Contrato de la API (describe)

`describe` muestra, sin llamar a la API, el contrato de cualquier operación: parámetros, forma y esquema del cuerpo, esquema de la respuesta, ejemplos de la documentación, notas de uso y los comandos que la llaman. Usa los mismos nombres de acción que el servidor MCP. Con `-j` la salida es JSON.

```bash
facturadirecta describe                              # Secciones de la API
facturadirecta describe invoices                     # Acciones de una sección, con su comando
facturadirecta describe create_invoice               # Contrato de una acción (o su operationId, createInvoice)
facturadirecta describe invoices create              # El mismo, por la ruta del comando
facturadirecta describe create_invoice --schema body # Esquema JSON completo del cuerpo
facturadirecta describe create_invoice --example     # Cuerpo de ejemplo, listo para --data
```

La ayuda (`--help`) de cada comando termina con la forma del cuerpo y el `describe` de su operación.

### Cualquier operación de la API (api)

`api` llama a cualquier operación del contrato por su nombre de acción (el de `describe`), también las que no tienen comando propio: pedidos, órdenes de compra, versiones de documentos, campos personalizados, stock o actividad. Valida la operación y los parámetros contra el contrato; el cuerpo lo valida la API. La respuesta sale tal cual en JSON.

```bash
facturadirecta api list_client_orders -p state=pending -p limit=50 -q   # -p nombre=valor: parámetros de query
facturadirecta api get_invoice_version inv_xxx VERSION_ID               # ids de la ruta, en orden
facturadirecta api create_custom_field --data @campo.json --idempotency-key "$(uuidgen)"
facturadirecta api update_invoice_tags inv_xxx --data '{"tags":["a"],"tagsOperation":"add"}' --dry-run   # la petición, sin enviarla
facturadirecta api delete_client_order cor_xxx --yes                    # los borrados piden confirmación
```

La empresa va con `--company` (o la del perfil), las escrituras necesitan `login --scope full` y `--output <fichero>` guarda el cuerpo de la respuesta. `--dry-run` nunca muestra credenciales.

### Consulta analítica (query)

`query` responde en una llamada lo que antes exigía listar y sumar: una fuente (`--from invoices`, `invoiceLines`, `bills`, `billLines`, `contacts` o `journal`), medidas, hasta dos dimensiones por las que agrupar, un periodo con comparativa o desglose, filtros y límite. En la terminal, una tabla con los grupos ordenados, la fila de otros y los totales; con `-j` o `-q`, el JSON de la API (`columns`, `rows`, `totals`, `other`, `truncated`). Es la misma acción `query` del servidor MCP.

```bash
facturadirecta query --from invoices --by contact --measures totalBeforeTaxes,count --period 2026 --limit 5 --other   # Mejores clientes del año
facturadirecta query --from invoices --by fiscalId --measures totalBeforeTaxes,contacts --limit 5                     # Mejores clientes por NIF, reuniendo los contactos duplicados
facturadirecta query --from contacts --by fiscalId --measures count --limit 20                                        # Contactos duplicados (mismo NIF)
facturadirecta query --from invoices --measures count,total,pending --filter "state in overdue"                       # Facturas vencidas: cuántas y cuánto suman
facturadirecta query --from bills --by contact --period 2026-09 --limit 100                                           # Gastos de septiembre por proveedor
facturadirecta query --from invoices --by contact.region --compare previousPeriod --limit 5                           # Provincias con más facturación frente al periodo anterior
facturadirecta query --from contacts --by address.region --filter isClient=true --limit 5                             # Provincias con más clientes
facturadirecta query --from invoices --measures totalBeforeTaxes --breakdown month --period 2026 --limit 12           # Facturación mes a mes
facturadirecta query --from invoiceLines --by product --measures totalBeforeTaxes,quantity --filter hasProduct=true --limit 5  # Productos más vendidos
facturadirecta query --from billLines --by product --measures quantity,totalBeforeTaxes,averagePrice --limit 20       # Qué compro y a qué precio medio
facturadirecta query --from invoiceLines --by contact,product --measures quantity --filter hasProduct=true --limit-per-group 3 --limit 100  # Los tres productos que más vendo a cada cliente
facturadirecta query --from journal --measures net --by contact --filter "account startsWith 7" --limit 5             # Ventas de las cuentas 7 por cliente (módulo de Contabilidad)
facturadirecta query --data '{"from":"invoices","dimensions":["country"],"limit":5}' -j                               # La petición completa en JSON
facturadirecta describe query                                                                                         # Vocabulario de cada fuente y ejemplos
```

`--period` admite un año (`2026`), un trimestre (`2026-Q3`), un mes (`2026-09`) o dos fechas (`2026-01-01..2026-06-30`); sin él, el año en curso. `--filter` se repite: `campo=valor`, `'campo in a,b'`, `campo>=valor`, `'campo between a,b'`, `campo^=prefijo`. Las cifras de `invoices` y `bills` son las de los documentos; las de `journal`, las del diario, y exigen el módulo de Contabilidad. `invoiceLines` y `billLines` son las líneas de esas facturas, con su producto (`--by product`) y su cantidad (`quantity`); `--filter hasProduct=true` deja fuera las de texto libre. Con dos dimensiones, `--limit-per-group` deja las primeras filas de la segunda dentro de cada valor de la primera, y `--amounts company` da los importes en la moneda de la empresa aunque haya varias. Los cobros a fondo (`daysToPayment`, `daysOverdue`, `agingBucket`) y el margen (`cost`, `margin`, `marginRate`) solo están en los planes de pago: sin ellos, `plan_limit_exceeded`.

`invoices list` y `bills list` admiten `--totals`: añade a la respuesta el recuento y la suma de la base imponible, los impuestos, el total y el pendiente de todo lo que cumple los filtros, por moneda (en la terminal, bajo la tabla; en JSON, con `-j`).

### Borrados

Los borrados irreversibles (`delete` de documentos, contactos, productos, métodos de pago, API keys y webhooks, y `attachments delete`) piden confirmación: en una terminal preguntan `[s/N]`; en scripts y agentes hace falta `--yes`, y sin él fallan con `confirmation_required` (exit 2) sin llamar a la API. Archivar un item de la bandeja y desconciliar un extracto no lo piden porque se pueden deshacer.

```bash
facturadirecta invoices delete inv_xxx --yes
```

### Otros recursos

```bash
facturadirecta banks list                       # Cuentas bancarias
facturadirecta banks list --related balance     # Con su saldo contable (el de la web y el de la contabilidad)
facturadirecta banks get ban_xxx --related balance,linkedBalance,link,statements   # Saldo contable, saldo según la entidad, enlace y pendientes
facturadirecta banks get ban_xxx --balance-date 2026-09-30                         # Saldo contable al cierre de un día
facturadirecta payment-methods list             # Métodos de pago
facturadirecta journal                          # Diario contable (apuntes; módulo de Contabilidad)
facturadirecta accounting results --breakdown quarter --total   # Ingresos, gastos y beneficio del año por trimestres
facturadirecta accounting results --compare previousYear        # Frente al año anterior
facturadirecta accounting results-documents --category invoices # Documentos de una cifra del resumen
facturadirecta accounting profit-loss                           # Pérdidas y ganancias (módulo de Contabilidad)
facturadirecta accounting balance-sheet --date 2026-12-31       # Balance de situación (módulo de Contabilidad)
facturadirecta accounting trial-balance --account 43            # Sumas y saldos (módulo de Contabilidad)
facturadirecta tax-declarations list            # Modelos de impuestos generados (303, 111, 130, 347…)
facturadirecta tax-declarations list --form 303 --fiscal-year 2026   # Los 303 de un ejercicio, con su resultado
facturadirecta tax-declarations get tax_xxx     # Un modelo con sus casillas (--related records añade los terceros de las informativas)
facturadirecta tax-declarations pdf tax_xxx     # PDF resumen del modelo
facturadirecta tax-declarations aeat-file tax_xxx   # Fichero de presentación de la AEAT
facturadirecta settings company                 # Ficha de la empresa: datos fiscales, modo borrador, bloqueo contable, módulos, buzón
facturadirecta settings taxes-sales             # Impuestos de ventas
facturadirecta settings taxes-purchases         # Impuestos de compras
facturadirecta settings series invoice          # Series de facturas
facturadirecta settings themes                  # Temas de diseño
facturadirecta webhooks endpoints list          # Webhooks configurados
facturadirecta webhooks events list             # Eventos de webhooks
```

## Formato de salida

| Flag | Descripción | Ejemplo |
|------|-------------|---------|
| *(tabla)* | Por defecto en terminal | `facturadirecta invoices list` |
| `--json` / `-j` | JSON completo | `facturadirecta invoices list -j` |
| `--quiet` / `-q` | Solo datos, sin metadatos | `facturadirecta invoices list -q` |
| `--ids-only` | Solo UUIDs, uno por línea | `facturadirecta invoices list --ids-only` |
| `--count` | Solo el número de resultados | `facturadirecta invoices list --count` |
| `--jq <filtro>` | Filtro jq integrado | `facturadirecta invoices list --jq '.items[].content.main.total'` |
| `--summary` | Resumen compacto por elemento en las salidas JSON (id, número, fecha, contacto, totales, estado, saldo pendiente y url, el enlace en la aplicación web que devuelve la API); en `list` y `get` de facturas, presupuestos, gastos, contactos y productos | `facturadirecta invoices list -q --summary` |
| `--url` | Solo la URL del elemento en la aplicación web de FacturaDirecta, la que devuelve la API en `webUrl` (en `get`) | `facturadirecta invoices get <id> --url` |

```bash
# Ejemplos de combinación
facturadirecta invoices list -q --jq '.[].content.main.total'              # Totales
facturadirecta invoices list --ids-only | xargs -I{} facturadirecta invoices pdf {}  # PDFs en batch
facturadirecta invoices list --state overdue --count                        # Contar facturas vencidas
facturadirecta invoices list --state overdue --summary -q                   # Vencidas con estado y saldo pendiente
```

## Errores

En modo agente (`-j`, `-q`, `--agent` o `--jq`) los errores van a stderr como una línea JSON con `code`, `message`, `status`, `detail`, `hint` y `data`, y stdout queda vacío. Sin esos flags, texto: `Error: HTTP 404: {...}` y el comando sugerido. Códigos de salida por clase: 2 uso, entrada no válida o borrado sin confirmar (`confirmation_required`: repite con `--yes`), 3 sesión, solo lectura o permisos, 4 no encontrado, 5 empresa sin indicar, 6 error de la API o de red, 1 cualquier otro.

Cuando la API rechaza una operación por la conexión (403), el código dice qué
hacer (todos con exit 3; el texto para humanos es `Error: HTTP 403: <mensaje>`):

| Código | Qué hacer |
|---|---|
| `connection_permission_insufficient`, `company_not_in_connection` | Ampliar la conexión (permiso o empresa) en la URL de `data.manageUrl` o con `facturadirecta auth permissions`; no hace falta volver a iniciar sesión |
| `user_role_insufficient` | Tu rol en la empresa no lo permite: pídeselo a un administrador de la empresa |
| `plan_api_not_available` | El plan de la empresa no incluye el acceso por API |
| `token_scope_missing` | La sesión no tiene el permiso (`data.requiredScope`): `facturadirecta login --scope full` |
| `connection_required`, `connection_revoked` | El perfil no tiene conexión o se ha revocado: `facturadirecta login` |

```bash
facturadirecta invoices get inv_inexistente -q
# stderr: {"error":{"code":"not_found","status":404,"message":"El recurso solicitado no existe en FacturaDirecta.","detail":"Not found"}}
# exit 4
```

## Paginación

Los comandos de listado devuelven 25 resultados por defecto (máximo 500):

```bash
facturadirecta invoices list --limit 50              # Más resultados
facturadirecta invoices list --offset 25             # Siguiente página
facturadirecta invoices list --limit 100 --offset 0  # Primeros 100
```

## Integración con asistentes de IA (MCP)

La integración con Claude, Cursor, VS Code, ChatGPT y otros clientes MCP se realiza contra el servidor remoto oficial:

```
https://mcp.facturadirecta.com
```

El servidor utiliza OAuth 2.1 con los mismos permisos que el CLI y está siempre sincronizado con la última versión de la API. Configúralo desde la UI del cliente (Connectors en Claude Desktop, `mcp.json` en Cursor, etc.).

> En próximas versiones el CLI incluirá un comando `facturadirecta mcp-install` que automatiza esta configuración en cada cliente.

## Almacenamiento de credenciales

Las credenciales se almacenan en un fichero local con permisos `0600`:

- macOS: `~/Library/Application Support/facturadirecta/credentials.json`
- Linux: `~/.config/facturadirecta/credentials.json`
- Windows: `%APPDATA%/facturadirecta/credentials.json`

Soporta múltiples perfiles:

```bash
facturadirecta login --profile trabajo
facturadirecta login --profile personal --api-key <key> --company <id>
facturadirecta auth status  # Ver el perfil activo
```

Cada perfil OAuth guarda además su conexión (id, secreto y URL para
gestionarla) y el cliente OAuth con el que se inició sesión. El secreto de la
conexión nunca se muestra.

## Licencia

MIT
