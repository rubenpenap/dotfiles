#!/usr/bin/env python3

from __future__ import annotations

import argparse
import secrets
import string
import sys

DEFAULT_LENGTH = 20
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


def main() -> int:
    args = parse_args()

    try:
        password = generate_password(args.length, args.special)
    except ValueError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(password)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
