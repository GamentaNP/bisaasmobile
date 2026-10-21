# -*- coding: utf-8 -*-
"""Adds the import and the `l10n` binding the rewritten strings need.

Run after `tool/apply_localization.py --apply`:

  * every file that uses `l10n.` gets the generated-localisations import;
  * every declaration that uses `l10n.` and has a `BuildContext` in scope
    gets `final l10n = AppLocalizations.of(context)!;` at the top of its body.

The declarations without a context — services, controllers, data sources —
are listed at the end and have to be handled by hand, because the
context-free lookup is a different thing.

    python tool/apply_localization_plumbing.py
"""

import io
import json
import os
import re
import shutil
import subprocess
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def dart_executable():
    found = shutil.which("dart")
    if found:
        return found
    for candidate in (r"C:\src\flutter\bin\dart.bat", r"C:\src\flutter\bin\dart.exe"):
        if os.path.exists(candidate):
            return candidate
    raise SystemExit("cannot find the dart executable")


def import_path_for(file):
    """The relative import from `file` to `lib/l10n/app_localizations.dart`."""
    depth = len(file.split("/")) - 2  # minus `lib/` and the file name
    return "../" * depth + "l10n/app_localizations.dart"


def load_uses():
    out = subprocess.run(
        [
            dart_executable(),
            "run",
            os.path.join("tool", "localization_plumbing.dart"),
        ],
        cwd=BASE,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    lines = out.stdout.splitlines()
    uses = {}
    current = None
    for line in lines:
        if line.startswith("--- "):
            break
        if line and not line.startswith("    "):
            current = line.strip()
            uses[current] = []
        elif line.startswith("    ") and current:
            m = re.match(
                r"\s*(\w+) (\S+)\s+context=(\w+)\s+at=(\d+)\s+body=(\w+)", line
            )
            if m:
                uses[current].append(
                    {
                        "kind": m.group(1),
                        "name": m.group(2),
                        "context": m.group(3) == "true",
                        "offset": int(m.group(4)),
                        "body": m.group(5),
                    }
                )
    return uses


def add_import(source, file):
    if "app_localizations.dart" in source:
        return source
    relative = import_path_for(file)
    statement = "import '%s';" % relative
    imports = list(re.finditer(r"^import .*?;$", source, re.MULTILINE))
    if imports:
        last = imports[-1]
        return source[: last.end()] + "\n" + statement + source[last.end():]
    # No imports yet — put it before the first declaration.
    match = re.search(r"^(library;|import |part )", source, re.MULTILINE)
    if match:
        return source[: match.start()] + statement + "\n\n" + source[match.start():]
    return statement + "\n\n" + source


def indent_at(source, offset):
    """The indentation of the first line after `offset`."""
    tail = source[offset:]
    newline = tail.find("\n")
    if newline == -1:
        return "    "
    line = tail[newline + 1:]
    stripped = line.lstrip()
    if not stripped:
        return "    "
    return line[: len(line) - len(stripped)]


def read_source(path):
    """The file's text, and the encoding to write it back with.

    A UTF-8 BOM has to be stripped before the offsets are used: Dart's
    `readAsStringSync` skips it, so the analyzer's offsets do not count it.
    """
    with io.open(path, "rb") as fh:
        raw = fh.read()
    has_bom = raw[:3] == b"\xef\xbb\xbf"
    encoding = "utf-8-sig" if has_bom else "utf-8"
    with io.open(path, encoding=encoding, newline="") as fh:
        return fh.read(), encoding


def main():
    uses = load_uses()
    manual = []

    for file, declarations in uses.items():
        path = os.path.join(BASE, file.replace("/", os.sep))
        source, encoding = read_source(path)

        insertions = []
        for declaration in declarations:
            if not declaration["context"]:
                manual.append((file, declaration["name"], "no BuildContext"))
                continue
            if declaration.get("body") != "block":
                manual.append((file, declaration["name"], "expression body"))
                continue
            offset = declaration["offset"]
            # Skip a declaration that already binds `l10n`.
            window = source[offset : offset + 400]
            if re.search(r"\b(?:final|var|const)\s+l10n\s*=", window):
                continue
            indent = indent_at(source, offset)
            insertions.append(
                (
                    offset,
                    "\n%sfinal l10n = AppLocalizations.of(context)!;" % indent,
                )
            )

        for offset, text in sorted(insertions, key=lambda i: i[0], reverse=True):
            source = source[:offset] + text + source[offset:]

        source = add_import(source, file)

        # Build the content before opening the file: opening truncates, so a
        # failure while building would leave an empty source file.
        with io.open(path, "w", encoding=encoding, newline="") as fh:
            fh.write(source)
        print("plumbed %s (%d declarations)" % (file, len(insertions)))

    if manual:
        print("\nno automatic binding — handle these by hand:")
        for file, name, why in manual:
            print("  %s  ->  %s  (%s)" % (file, name, why))


if __name__ == "__main__":
    main()
