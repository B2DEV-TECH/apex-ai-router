#!/usr/bin/env python3
"""Assemble the GitHub release assets listed in the implementation spec
(section 38) into `dist/release/` for a maintainer to attach to a GitHub
Release (`gh release create ... dist/release/*`).

    uv run --project gateway python scripts/build_release_artifacts.py

This script only copies/zips files that already exist in the repository --
it never invents content. One listed asset,
`apex-ai-router-plugin.sql`, is intentionally NOT produced: it is the
APEX Builder plug-in export, which requires a live APEX Builder instance to
generate (see `apex-plugin/dist/README.md` and `HANDOFF.md`). Producing a
hand-written substitute risks shipping a file that fails to import, so this
script prints a warning and skips it instead of fabricating one.
"""

import shutil
import sys
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = REPO_ROOT / "dist" / "release"


def build_database_zip() -> None:
    database_dir = REPO_ROOT / "database"
    zip_path = OUTPUT_DIR / "apex-ai-router-database.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(database_dir.rglob("*")):
            if path.is_file():
                zf.write(path, arcname=Path("database") / path.relative_to(database_dir))
    print(f"wrote {zip_path.relative_to(REPO_ROOT)}")


def copy_file(source: Path, dest_name: str) -> None:
    if not source.exists():
        print(f"SKIPPED {dest_name}: source {source.relative_to(REPO_ROOT)} does not exist")
        return
    shutil.copyfile(source, OUTPUT_DIR / dest_name)
    dest_rel = (OUTPUT_DIR / dest_name).relative_to(REPO_ROOT)
    print(f"wrote {dest_rel} (from {source.relative_to(REPO_ROOT)})")


def warn_plugin_sql_not_generated() -> None:
    print(
        "SKIPPED apex-ai-router-plugin.sql: this is APEX Builder's own "
        "plug-in export format, which requires a live APEX Builder instance "
        "to generate. See apex-plugin/dist/README.md and HANDOFF.md. Do not "
        "hand-write a substitute -- export it from a real Builder instance "
        "and place it in apex-plugin/dist/ before attaching it to a release."
    )


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    build_database_zip()
    copy_file(REPO_ROOT / "docker-compose.yml", "docker-compose.yml")
    copy_file(REPO_ROOT / ".env.example", "example.env")
    copy_file(
        REPO_ROOT / "benchmark" / "results" / "mock-example" / "report.md",
        "benchmark-report.md",
    )
    warn_plugin_sql_not_generated()

    print(f"\nRelease assets staged in {OUTPUT_DIR.relative_to(REPO_ROOT)}/")
    print(
        "benchmark-report.md is the mock-mode example run -- it documents its "
        "own limitations inline. It is not a real-provider cost/quality claim."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
