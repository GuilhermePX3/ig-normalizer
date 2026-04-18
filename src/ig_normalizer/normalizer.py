"""Core normalization logic for filenames and file contents."""

import unicodedata
import re
import os
from pathlib import Path
from typing import Optional


# Full character replacement map for characters that do NOT decompose via NFKD
# (ligatures, special typographic chars, etc.)
EXTRA_REPLACEMENTS: dict[str, str] = {
    # --- Latin ligatures / special letters ---
    "Æ": "AE", "æ": "ae",
    "Œ": "OE", "œ": "oe",
    "Ð": "D",  "ð": "d",
    "Þ": "TH", "þ": "th",
    "ß": "ss",
    "Ł": "L",  "ł": "l",
    "Ø": "O",  "ø": "o",
    "Đ": "D",  "đ": "d",
    "Ħ": "H",  "ħ": "h",
    "ı": "i",  "İ": "I",
    "ĸ": "k",
    "Ŋ": "N",  "ŋ": "n",
    "ŉ": "n",
    "Ŧ": "T",  "ŧ": "t",
    # --- Portuguese / Spanish specific that survive NFKD ---
    # (Most are handled by NFKD, but ñ/ã/ç etc. are covered there)
    # --- Typographic / punctuation ---
    "\u2018": "'",  # left single quotation mark
    "\u2019": "'",  # right single quotation mark
    "\u201C": '"',  # left double quotation mark
    "\u201D": '"',  # right double quotation mark
    "\u2013": "-",  # en dash
    "\u2014": "-",  # em dash
    "\u2026": "...",# horizontal ellipsis
    "\u00B7": ".",  # middle dot
    "\u00A0": " ",  # non-breaking space
    "\u00AD": "",   # soft hyphen (invisible, just remove)
    # --- Currency / misc symbols that might appear in paths ---
    "\u20AC": "EUR",
    "\u00A3": "GBP",
    "\u00A5": "JPY",
    "\u00A9": "(c)",
    "\u00AE": "(r)",
    "\u2122": "(tm)",
}


def _apply_extra_replacements(text: str) -> str:
    for src, dst in EXTRA_REPLACEMENTS.items():
        text = text.replace(src, dst)
    return text


def normalize_string(text: str, keep_case: bool = True) -> str:
    """
    Convert a string so that it contains only ASCII-safe characters:
      1. Apply extra replacements (ligatures, typographic chars, etc.)
      2. NFKD decompose → strip combining diacritical marks (accents, tildes, cedillas…)
      3. Encode to ASCII (ignore remaining non-ASCII)
      4. Optionally lower-case

    Examples
    --------
    "Atlético MG"  → "Atletico MG"
    "Criciúma"     → "Criciuma"
    "Goiás"        → "Goias"
    "São Paulo"    → "Sao Paulo"
    "Ñoño"         → "Nono"
    """
    text = _apply_extra_replacements(text)
    # NFKD decomposition strips combining characters (accents, cedillas, tildes…)
    nfkd = unicodedata.normalize("NFKD", text)
    ascii_text = nfkd.encode("ascii", errors="ignore").decode("ascii")
    if not keep_case:
        ascii_text = ascii_text.lower()
    return ascii_text


# ---------------------------------------------------------------------------
# File content helpers
# ---------------------------------------------------------------------------

# Encodings to try when reading text files (order matters)
_ENCODINGS = ["utf-8", "utf-8-sig", "latin-1", "cp1252"]

# Extensions treated as text files (add more as needed)
TEXT_EXTENSIONS: set[str] = {
    ".ini", ".cfg", ".txt", ".csv", ".json", ".xml", ".yaml", ".yml",
    ".properties", ".conf", ".log", ".md", ".rst", ".bat", ".sh",
    ".html", ".htm", ".css", ".js", ".ts", ".py",
}


def _read_text(path: Path) -> tuple[str, str]:
    """Return (content, encoding) for the first encoding that works."""
    for enc in _ENCODINGS:
        try:
            return path.read_text(encoding=enc), enc
        except (UnicodeDecodeError, LookupError):
            continue
    raise ValueError(f"Cannot decode file: {path}")


def normalize_file_content(path: Path, dry_run: bool = False) -> bool:
    """
    Normalize accented characters INSIDE a text file.
    Returns True if the file was (or would be) modified.
    """
    if path.suffix.lower() not in TEXT_EXTENSIONS:
        return False

    try:
        original, enc = _read_text(path)
    except ValueError:
        return False

    normalized = normalize_string(original)

    if normalized == original:
        return False  # nothing to do

    if not dry_run:
        path.write_text(normalized, encoding="utf-8")

    return True


# ---------------------------------------------------------------------------
# Filesystem renaming helpers
# ---------------------------------------------------------------------------

def normalize_path_component(name: str) -> str:
    """Normalize a single filename or directory name component."""
    return normalize_string(name, keep_case=True)


def compute_new_name(old_name: str) -> Optional[str]:
    """Return the normalized name, or None if no change is needed."""
    new_name = normalize_path_component(old_name)
    return new_name if new_name != old_name else None


# ---------------------------------------------------------------------------
# Walk and process
# ---------------------------------------------------------------------------

class NormalizerStats:
    def __init__(self) -> None:
        self.files_renamed: int = 0
        self.dirs_renamed: int = 0
        self.contents_changed: int = 0
        self.errors: list[str] = []

    def summary(self) -> str:
        lines = [
            f"  Files renamed      : {self.files_renamed}",
            f"  Dirs renamed       : {self.dirs_renamed}",
            f"  File contents fixed: {self.contents_changed}",
        ]
        if self.errors:
            lines.append(f"  Errors             : {len(self.errors)}")
        return "\n".join(lines)


def process_directory(
    root: Path,
    *,
    dry_run: bool = False,
    verbose: bool = False,
    fix_contents: bool = True,
    fix_names: bool = True,
    recursive: bool = True,
) -> NormalizerStats:
    """
    Walk *root* and:
      - Rename files/dirs whose names contain accented/special characters.
      - Normalize the content of recognised text files.

    The walk is done bottom-up so that renaming a subdirectory does not
    invalidate the paths of items inside it.
    """
    stats = NormalizerStats()

    def log(msg: str) -> None:
        if verbose:
            print(msg)

    walker = os.walk(root, topdown=False) if recursive else _single_level_walk(root)

    for dirpath, dirnames, filenames in walker:
        current_dir = Path(dirpath)

        # --- Fix file contents and rename files ---
        for fname in filenames:
            fpath = current_dir / fname

            # 1. Fix content first (while the path is still valid)
            if fix_contents:
                try:
                    changed = normalize_file_content(fpath, dry_run=dry_run)
                    if changed:
                        tag = "[DRY-RUN] " if dry_run else ""
                        log(f"  {tag}Content fixed : {fpath}")
                        stats.contents_changed += 1
                except Exception as exc:
                    msg = f"ERROR reading {fpath}: {exc}"
                    stats.errors.append(msg)
                    if verbose:
                        print(f"  {msg}")

            # 2. Rename file if needed
            if fix_names:
                new_fname = compute_new_name(fname)
                if new_fname:
                    new_fpath = current_dir / new_fname
                    tag = "[DRY-RUN] " if dry_run else ""
                    log(f"  {tag}Rename file   : {fpath}  →  {new_fpath}")
                    if not dry_run:
                        try:
                            fpath.rename(new_fpath)
                            stats.files_renamed += 1
                        except Exception as exc:
                            msg = f"ERROR renaming {fpath}: {exc}"
                            stats.errors.append(msg)
                            if verbose:
                                print(f"  {msg}")
                    else:
                        stats.files_renamed += 1

        # --- Rename directories (bottom-up, so children are done first) ---
        if fix_names:
            dname = current_dir.name
            if dname and current_dir != root:
                new_dname = compute_new_name(dname)
                if new_dname:
                    new_dpath = current_dir.parent / new_dname
                    tag = "[DRY-RUN] " if dry_run else ""
                    log(f"  {tag}Rename dir    : {current_dir}  →  {new_dpath}")
                    if not dry_run:
                        try:
                            current_dir.rename(new_dpath)
                            stats.dirs_renamed += 1
                        except Exception as exc:
                            msg = f"ERROR renaming dir {current_dir}: {exc}"
                            stats.errors.append(msg)
                            if verbose:
                                print(f"  {msg}")
                    else:
                        stats.dirs_renamed += 1

    return stats


def _single_level_walk(root: Path):
    """Yield a single (dirpath, dirnames, filenames) tuple — non-recursive."""
    entries = list(root.iterdir())
    dirnames = [e.name for e in entries if e.is_dir()]
    filenames = [e.name for e in entries if e.is_file()]
    yield str(root), dirnames, filenames
