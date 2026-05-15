from __future__ import annotations

import argparse
import secrets
import string
import subprocess
import sys
from collections.abc import Sequence

DEFAULT_LENGTH = 30
SPECIAL_CHARACTERS = "!@#$%^&*()-_=+[]{};:,.?/|~"
_RNG = secrets.SystemRandom()


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Genera contraseñas seguras usando un RNG criptográficamente seguro."
    )
    parser.add_argument(
        "-s",
        "--special",
        action="store_true",
        help="Incluye caracteres especiales.",
    )
    parser.add_argument(
        "-l",
        "--length",
        type=int,
        default=DEFAULT_LENGTH,
        help=f"Largo de la contraseña (default: {DEFAULT_LENGTH}).",
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="Imprime la contraseña en stdout.",
    )
    parser.add_argument(
        "--no-clipboard",
        action="store_true",
        help="No copia la contraseña al portapapeles.",
    )
    return parser


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = create_parser()
    args = parser.parse_args(argv)

    if args.length <= 0:
        parser.error("el largo debe ser un entero positivo")

    if args.no_clipboard and not args.show:
        parser.error("usá --show si desactivás el portapapeles")

    return args


def build_required_sets(include_special: bool) -> list[str]:
    sets = [string.ascii_lowercase, string.ascii_uppercase, string.digits]

    if include_special:
        sets.append(SPECIAL_CHARACTERS)

    return sets


def generate_password(length: int, include_special: bool) -> str:
    required_sets = build_required_sets(include_special)

    if length < len(required_sets):
        raise ValueError(
            f"el largo mínimo para esta configuración es {len(required_sets)}"
        )

    alphabet = "".join(required_sets)
    password_chars = [_RNG.choice(charset) for charset in required_sets]
    password_chars.extend(
        _RNG.choice(alphabet) for _ in range(length - len(password_chars))
    )
    _RNG.shuffle(password_chars)

    return "".join(password_chars)


def copy_to_clipboard(password: str) -> None:
    try:
        subprocess.run(["pbcopy"], input=password, text=True, check=True)
    except FileNotFoundError as error:
        raise RuntimeError("pbcopy no está disponible en este sistema") from error
    except subprocess.CalledProcessError as error:
        raise RuntimeError("no se pudo copiar la contraseña al portapapeles") from error


def emit_password(password: str, *, show: bool, copy: bool) -> None:
    clipboard_error: RuntimeError | None = None

    if copy:
        try:
            copy_to_clipboard(password)
        except RuntimeError as error:
            clipboard_error = error

    if show:
        print(password)

    if clipboard_error is not None:
        if show:
            print(f"Aviso: {clipboard_error}", file=sys.stderr)
            return
        raise clipboard_error

    if copy:
        print("Contraseña copiada al portapapeles.", file=sys.stderr)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)

    try:
        password = generate_password(args.length, args.special)
        emit_password(password, show=args.show, copy=not args.no_clipboard)
    except ValueError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    except RuntimeError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    return 0
