from __future__ import annotations

import io
import unittest
from contextlib import redirect_stderr, redirect_stdout
from unittest.mock import patch

from tools import password_generator as pg


class GeneratePasswordTests(unittest.TestCase):
    def test_generate_password_uses_requested_length(self) -> None:
        password = pg.generate_password(40, include_special=False)

        self.assertEqual(len(password), 40)

    def test_generate_password_includes_required_character_sets(self) -> None:
        password = pg.generate_password(60, include_special=True)

        self.assertTrue(any(char.islower() for char in password))
        self.assertTrue(any(char.isupper() for char in password))
        self.assertTrue(any(char.isdigit() for char in password))
        self.assertTrue(any(char in pg.SPECIAL_CHARACTERS for char in password))

    def test_generate_password_rejects_too_short_lengths(self) -> None:
        with self.assertRaises(ValueError):
            pg.generate_password(2, include_special=False)

        with self.assertRaises(ValueError):
            pg.generate_password(3, include_special=True)


class ParseArgsTests(unittest.TestCase):
    def test_parse_args_defaults(self) -> None:
        args = pg.parse_args([])

        self.assertEqual(args.length, pg.DEFAULT_LENGTH)
        self.assertFalse(args.special)
        self.assertFalse(args.show)
        self.assertFalse(args.no_clipboard)

    def test_parse_args_requires_visible_output_when_clipboard_disabled(self) -> None:
        with self.assertRaises(SystemExit):
            pg.parse_args(["--no-clipboard"])


class MainTests(unittest.TestCase):
    def test_main_returns_success_when_password_is_shown_despite_clipboard_warning(
        self,
    ) -> None:
        stdout = io.StringIO()
        stderr = io.StringIO()

        with (
            patch.object(pg, "generate_password", return_value="secret"),
            patch.object(
                pg, "copy_to_clipboard", side_effect=RuntimeError("sin portapapeles")
            ),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            exit_code = pg.main(["--show"])

        self.assertEqual(exit_code, 0)
        self.assertEqual(stdout.getvalue().strip(), "secret")
        self.assertIn("Aviso: sin portapapeles", stderr.getvalue())

    def test_main_returns_error_when_clipboard_is_required_and_fails(self) -> None:
        stderr = io.StringIO()

        with (
            patch.object(pg, "generate_password", return_value="secret"),
            patch.object(
                pg, "copy_to_clipboard", side_effect=RuntimeError("sin portapapeles")
            ),
            redirect_stderr(stderr),
        ):
            exit_code = pg.main([])

        self.assertEqual(exit_code, 1)
        self.assertIn("Error: sin portapapeles", stderr.getvalue())


class EmitPasswordTests(unittest.TestCase):
    def test_emit_password_prints_and_warns_when_clipboard_fails(self) -> None:
        stdout = io.StringIO()
        stderr = io.StringIO()

        with (
            patch.object(
                pg, "copy_to_clipboard", side_effect=RuntimeError("sin portapapeles")
            ),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            pg.emit_password("secret", show=True, copy=True)

        self.assertEqual(stdout.getvalue().strip(), "secret")
        self.assertIn("Aviso: sin portapapeles", stderr.getvalue())

    def test_emit_password_confirms_clipboard_copy(self) -> None:
        stderr = io.StringIO()

        with (
            patch.object(pg, "copy_to_clipboard") as copy_mock,
            redirect_stderr(stderr),
        ):
            pg.emit_password("secret", show=False, copy=True)

        copy_mock.assert_called_once_with("secret")
        self.assertIn("Contraseña copiada al portapapeles.", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
