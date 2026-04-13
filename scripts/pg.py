#!/usr/bin/env python3

from __future__ import annotations

import argparse
import secrets
import string
import subprocess
import sys

DEFAULT_LENGTH = 30
SPECIAL_CHARACTERS = "!@#$%^&*()-_=+[]{};:,.?/|~"


def parse_args() -> argparse.Namespace:
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

    args = parser.parse_args()

    if args.length <= 0:
        parser.error("el largo debe ser un entero positivo")

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
    password_chars = [secrets.choice(charset) for charset in required_sets]
    password_chars.extend(secrets.choice(alphabet) for _ in range(length - len(password_chars)))
    secrets.SystemRandom().shuffle(password_chars)

    return "".join(password_chars)


def copy_to_clipboard(password: str) -> None:
    try:
        subprocess.run(["pbcopy"], input=password, text=True, check=True)
    except FileNotFoundError as error:
        raise RuntimeError("pbcopy no está disponible en este sistema") from error
    except subprocess.CalledProcessError as error:
        raise RuntimeError("no se pudo copiar la contraseña al clipboard") from error


def main() -> int:
    args = parse_args()

    try:
        password = generate_password(args.length, args.special)
        copy_to_clipboard(password)
    except ValueError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    except RuntimeError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
