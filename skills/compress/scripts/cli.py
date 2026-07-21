#!/usr/bin/env python3
"""
Terse compress — local helper CLI.

No LLM calls happen here. The acting agent (Claude, running this skill
inside Claude Code) does the actual compression itself via its own Read/Edit
tools; these subcommands only handle the deterministic parts: classifying a
file, guarding against sensitive paths, managing the out-of-tree backup, and
validating that a compression preserved structure.

Usage:
    python3 -m scripts detect   <filepath>
    python3 -m scripts backup   <filepath>
    python3 -m scripts validate <original_or_backup_path> <compressed_path>

Exit codes for `detect`:
    0  proceed — natural language, not sensitive, within size cap
    2  skip    — not natural language (code/config); nothing to do
    3  refuse  — path looks like it holds credentials/secrets; hard stop
    1  error   — not found, not a file, too large, or empty
"""

import os
import re
import sys
from pathlib import Path

try:
    from .detect import detect_file_type, should_compress
    from .validate import validate
except ImportError:
    sys.path.insert(0, str(Path(__file__).parent))
    from detect import detect_file_type, should_compress
    from validate import validate

MAX_FILE_SIZE = 500_000  # 500KB

# Filenames and paths that almost certainly hold secrets or PII. detect.py
# already skips .env by extension, but credentials.md / secrets.txt /
# ~/.aws/credentials would slip through the natural-language filter. Hard
# refuse before any read — independent of any network boundary, this just
# prevents ever rewriting a file that looks like it holds credentials.
SENSITIVE_BASENAME_REGEX = re.compile(
    r"(?ix)^("
    r"\.env(\..+)?"
    r"|\.netrc"
    r"|credentials(\..+)?"
    r"|secrets?(\..+)?"
    r"|passwords?(\..+)?"
    r"|id_(rsa|dsa|ecdsa|ed25519)(\.pub)?"
    r"|authorized_keys"
    r"|known_hosts"
    r"|.*\.(pem|key|p12|pfx|crt|cer|jks|keystore|asc|gpg)"
    r")$"
)

SENSITIVE_PATH_COMPONENTS = frozenset({".ssh", ".aws", ".gnupg", ".kube", ".docker"})

SENSITIVE_NAME_TOKENS = (
    "secret", "credential", "password", "passwd",
    "apikey", "accesskey", "token", "privatekey",
)


def is_sensitive_path(filepath: Path) -> bool:
    """Heuristic denylist for files that must never be rewritten by this skill."""
    name = filepath.name
    if SENSITIVE_BASENAME_REGEX.match(name):
        return True
    lowered_parts = {p.lower() for p in filepath.parts}
    if lowered_parts & SENSITIVE_PATH_COMPONENTS:
        return True
    # Normalize separators so "api-key" and "api_key" both match "apikey".
    lower = re.sub(r"[_\-\s.]", "", name.lower())
    return any(tok in lower for tok in SENSITIVE_NAME_TOKENS)


def backup_dir_for(filepath: Path) -> Path:
    """Resolve the out-of-tree backup directory for a given source file.

    Backups live OUTSIDE the source directory so skill auto-loaders (Claude
    Code rules/, opencode instructions/, etc.) don't re-ingest the
    `.original.md` copy as a live file. Base dir is platform-aware:
      - Windows: %LOCALAPPDATA%\\terse\\compress-backups
      - else:    $XDG_DATA_HOME/terse/compress-backups if set,
                 else ~/.local/share/terse/compress-backups

    The source file's parent-dir name is mirrored under the base to reduce
    cross-project collisions (e.g. two `todo.md` files in different repos).
    """
    if os.name == "nt" or sys.platform == "win32":
        local_appdata = os.environ.get("LOCALAPPDATA")
        base = Path(local_appdata) if local_appdata else Path.home() / "AppData" / "Local"
        base = base / "terse" / "compress-backups"
    else:
        xdg = os.environ.get("XDG_DATA_HOME")
        base = Path(xdg) if xdg else Path.home() / ".local" / "share"
        base = base / "terse" / "compress-backups"
    return base / filepath.parent.name


def backup_path_for(filepath: Path) -> Path:
    return backup_dir_for(filepath) / (filepath.stem + ".original.md")


# ---------- Subcommands ----------


def cmd_detect(argv):
    if len(argv) != 1:
        print("Usage: cli.py detect <filepath>")
        return 1
    filepath = Path(argv[0])

    if not filepath.exists():
        print(f"error: file not found: {filepath}")
        return 1
    if not filepath.is_file():
        print(f"error: not a file: {filepath}")
        return 1

    filepath = filepath.resolve()
    size = filepath.stat().st_size
    if size > MAX_FILE_SIZE:
        print(f"error: file too large to compress safely (max 500KB): {filepath} ({size} bytes)")
        return 1

    if is_sensitive_path(filepath):
        print(f"refuse: {filepath} looks like it holds credentials/secrets — not compressing")
        print("        rename the file if this is a false positive")
        return 3

    file_type = detect_file_type(filepath)
    if not should_compress(filepath):
        print(f"skip: detected={file_type} — not natural language (code/config)")
        return 2

    text = filepath.read_text(errors="ignore")
    if not text.strip():
        print("error: file is empty or whitespace-only")
        return 1

    print(f"proceed: detected={file_type}")
    return 0


def cmd_backup(argv):
    if len(argv) != 1:
        print("Usage: cli.py backup <filepath>")
        return 1
    filepath = Path(argv[0]).resolve()

    if not filepath.exists() or not filepath.is_file():
        print(f"error: file not found: {filepath}")
        return 1

    original_text = filepath.read_text(errors="ignore")
    backup_dir = backup_dir_for(filepath)
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup_path = backup_path_for(filepath)

    if backup_path.exists():
        # Never clobber a possibly hand-edited original — skip the write but
        # still let the caller proceed, so rerunning after an edit actually
        # re-compresses instead of silently doing nothing.
        print(f"exists: {backup_path} — preserved, not overwritten")
        return 0

    backup_path.write_text(original_text)
    readback = backup_path.read_text(errors="ignore")
    if readback != original_text:
        print(f"error: backup write verification failed: {backup_path}")
        try:
            backup_path.unlink()
        except OSError:
            pass
        return 1

    print(f"created: {backup_path}")
    return 0


def cmd_validate(argv):
    if len(argv) != 2:
        print("Usage: cli.py validate <original_or_backup_path> <compressed_path>")
        return 1
    orig = Path(argv[0]).resolve()
    comp = Path(argv[1]).resolve()

    if not orig.exists():
        print(f"error: original not found: {orig}")
        return 1
    if not comp.exists():
        print(f"error: compressed file not found: {comp}")
        return 1

    result = validate(orig, comp)

    print(f"valid: {result.is_valid}")
    if result.errors:
        print("errors:")
        for e in result.errors:
            print(f"  - {e}")
    if result.warnings:
        print("warnings:")
        for w in result.warnings:
            print(f"  - {w}")

    return 0 if result.is_valid else 1


SUBCOMMANDS = {"detect": cmd_detect, "backup": cmd_backup, "validate": cmd_validate}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in SUBCOMMANDS:
        print(f"Usage: cli.py <{'|'.join(SUBCOMMANDS)}> <args...>")
        sys.exit(1)
    sys.exit(SUBCOMMANDS[sys.argv[1]](sys.argv[2:]))


if __name__ == "__main__":
    main()
