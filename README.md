# dotfiles

Setup personal de macOS y utilidades locales chicas. Este repo ahora está organizado en dos áreas claras: bootstrap/configuración de shell y herramientas ejecutables.

## Estructura

### Configuración del sistema

- `.macos`: bootstrap de una máquina nueva, instalación de herramientas y defaults de macOS.
- `.zshrc`: punto de entrada del shell.
- `shell/zsh/path.zsh`: armado de `PATH`.
- `shell/zsh/runtime.zsh`: carga de `nvm`, `pnpm` y `sdkman`.
- `shell/zsh/aliases.zsh`: aliases interactivos.
- `shell/zsh/functions.zsh`: funciones y helpers.

### Utilidades

- `bin/pg`: comando ejecutable principal.
- `tools/password_generator.py`: implementación reusable del generador de contraseñas.
- `scripts/pg.py`: wrapper legacy de compatibilidad para el path anterior.
- `tests/test_pg.py`: tests de lógica y CLI.
- `tests/test_wrappers.py`: tests de entrypoints reales fuera del root del repo.

## Password generator

### Requisitos

- Python 3.10+
- `pbcopy` disponible si querés copiar al portapapeles (macOS)

### Uso

```bash
./bin/pg
```

Por defecto:

- genera una contraseña de 30 caracteres;
- incluye minúsculas, mayúsculas y números;
- la copia al portapapeles;
- no la imprime en pantalla.

### Opciones útiles

```bash
# Incluir caracteres especiales
./bin/pg --special

# Elegir largo
./bin/pg --length 40

# Imprimir la contraseña además de copiarla
./bin/pg --show

# Imprimir sin copiar al portapapeles
./bin/pg --show --no-clipboard
```

También sigue funcionando el path anterior, pero el camino canónico ahora es `bin/pg`:

```bash
python3 scripts/pg.py --show
```

Si cargás este repo desde tu shell, también quedan disponibles:

```bash
pg
pgen
```

## Bootstrap de macOS

`./.macos` no es un script inocente: instala software, toca configuración del sistema y enlaza archivos en `$HOME`.

Antes de correrlo:

- revisalo completo;
- ajustá lo que no quieras instalar;
- entendé que modifica `~/.ssh/config`, `~/.zprofile`, symlinks de dotfiles y defaults de macOS.

## Tooling

Comandos útiles:

```bash
make test
make lint
make format
make check
```

- `make test` usa `unittest`, incluyendo verificación de wrappers reales.
- `make lint` y `make format` usan `ruff` con configuración en `pyproject.toml`.
- Si no tenés `ruff`, instalalo con `brew install ruff` o a través de `./.macos`.
