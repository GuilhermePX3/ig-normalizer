"""Command-line interface for ig-normalizer."""

import argparse
import sys
from pathlib import Path

try:
    from ig_normalizer.normalizer import process_directory, normalize_string
except ImportError:
    from normalizer import process_directory, normalize_string  # PyInstaller fallback


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ig-normalizer",
        description=(
            "Remove accents and special characters from filenames and file contents.\n"
            "Handles Portuguese/Spanish characters: á é í ó ú â ê î ô û ã õ ç ñ ü etc."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Preview what would change (safe — no writes)
  ig-normalizer /path/to/folder --dry-run --verbose

  # Fix everything recursively
  ig-normalizer /path/to/folder

  # Fix only file contents, do NOT rename files/dirs
  ig-normalizer /path/to/folder --no-rename

  # Fix only filenames, do NOT touch file contents
  ig-normalizer /path/to/folder --no-content

  # Non-recursive (only the given folder, no subdirectories)
  ig-normalizer /path/to/folder --no-recursive

  # Quick test: normalize a single string
  ig-normalizer --test "Atlético MG / Goiás / Ñoño"
        """,
    )

    parser.add_argument(
        "path",
        nargs="?",
        metavar="PATH",
        help="Root folder to process.",
    )

    parser.add_argument(
        "--dry-run", "-n",
        action="store_true",
        default=False,
        help="Simulate changes without writing anything to disk.",
    )

    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        default=False,
        help="Print every change (or would-be change) to stdout.",
    )

    parser.add_argument(
        "--no-rename",
        action="store_true",
        default=False,
        help="Skip renaming files and directories.",
    )

    parser.add_argument(
        "--no-content",
        action="store_true",
        default=False,
        help="Skip normalizing file contents.",
    )

    parser.add_argument(
        "--no-recursive",
        action="store_true",
        default=False,
        help="Process only the top-level folder (no subdirectories).",
    )

    parser.add_argument(
        "--test", "-t",
        metavar="STRING",
        default=None,
        help="Normalize a single string and print the result (no filesystem changes).",
    )

    parser.add_argument(
        "--version",
        action="version",
        version="ig-normalizer 1.0.6",
    )

    return parser


def main(argv=None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    # --test mode: just normalize a string and exit
    if args.test is not None:
        result = normalize_string(args.test)
        print(f"Input : {args.test!r}")
        print(f"Output: {result!r}")
        return 0

    if args.path is None:
        parser.print_help()
        return 1

    root = Path(args.path).expanduser().resolve()

    if not root.exists():
        print(f"ERROR: Path does not exist: {root}", file=sys.stderr)
        return 2

    if not root.is_dir():
        print(f"ERROR: Path is not a directory: {root}", file=sys.stderr)
        return 2

    fix_names = not args.no_rename
    fix_contents = not args.no_content
    recursive = not args.no_recursive

    mode_tag = "[DRY-RUN] " if args.dry_run else ""
    print(f"{mode_tag}ig-normalizer starting on: {root}")
    if args.dry_run:
        print("  (no changes will be written to disk)")
    print()

    stats = process_directory(
        root,
        dry_run=args.dry_run,
        verbose=args.verbose,
        fix_contents=fix_contents,
        fix_names=fix_names,
        recursive=recursive,
    )

    print()
    print("Done.")
    print(stats.summary())

    if stats.errors:
        print("\nErrors:")
        for err in stats.errors:
            print(f"  {err}")
        return 3

    return 0


if __name__ == "__main__":
    sys.exit(main())
