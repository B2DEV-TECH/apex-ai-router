"""Neutralize environment-specific defaults in an APEX application export.

APEX Builder writes the exporting workspace id, parsing schema and user name
into every export. None of them is needed to import the application (the
import wizard, or apex_application_install, supplies the target values), and
none of them belongs in a public repository. This script rewrites those
fields in place so the committed artifact carries no instance identifiers:

* ``p_default_workspace_id`` becomes ``0``
* ``p_default_owner`` and the ``p_owner=>nvl(...)`` fallback become ``CHANGE_ME``
* ``Exported By`` in the header comment becomes ``REDACTED``
* every ``p_created_by`` / ``p_updated_by`` / ``p_last_updated_by`` becomes ``REDACTED``

Everything else -- application id, id offset, pages, static files, plug-in
metadata -- is left untouched, so the file is still a byte-for-byte APEX
export apart from those fields.

Usage::

    python scripts/sanitize_apex_export.py <raw export.sql> <sanitized.sql>

Exits non-zero (and writes nothing) when the input does not look like an
APEX export or when the rewrite changed nothing, so a stale or already
sanitized file cannot be silently republished as "freshly exported".
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

RULES: list[tuple[str, str]] = [
    (r"(,p_default_workspace_id=>)\d+", r"\g<1>0"),
    (r"(,p_default_owner=>)'[^']*'", r"\g<1>'CHANGE_ME'"),
    (r"(,p_owner=>nvl\(wwv_flow_application_install\.get_schema,)'[^']*'\)", r"\g<1>'CHANGE_ME')"),
    (r"(--\s+Exported By:\s+)\S+", r"\g<1>REDACTED"),
    (r"(,p_(?:created|updated|last_updated)_by=>)'[^']*'", r"\g<1>'REDACTED'"),
]


def sanitize(text: str) -> tuple[str, int]:
    """Apply every rule and return the new text plus the number of fields that changed.

    Only fields whose value actually differs from the neutral one are counted,
    so running the script over an already sanitized file reports zero changes.
    """
    changed = 0
    for pattern, replacement in RULES:

        def swap(match: re.Match[str], replacement: str = replacement) -> str:
            nonlocal changed
            neutral = match.expand(replacement)
            if neutral != match.group(0):
                changed += 1
            return neutral

        text = re.sub(pattern, swap, text)
    return text, changed


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__.strip().splitlines()[0])
        print("usage: sanitize_apex_export.py <raw export.sql> <sanitized.sql>")
        return 2

    source, target = Path(argv[1]), Path(argv[2])
    raw = source.read_text(encoding="utf-8")
    if "wwv_flow_imp.import_begin" not in raw:
        print(f"{source}: not an APEX application export (no wwv_flow_imp.import_begin)")
        return 1

    clean, replacements = sanitize(raw)
    if replacements == 0:
        print(f"{source}: nothing to sanitize -- is this already a sanitized file?")
        return 1

    # Keep the export's own line endings; APEX writes LF and SQL*Plus accepts either.
    target.write_text(clean, encoding="utf-8", newline="")
    print(f"{target}: {replacements} field(s) neutralized")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
