# ig-normalizer

Remove accents and special characters from **filenames** and **file contents** — designed for game modding workflows (ISS Pro Evolution, PES, etc.) where decompression tools choke on non-ASCII characters.

## What it fixes

| Character         | Normalized          |
| ----------------- | ------------------- |
| á é í ó ú         | a e i o u           |
| â ê î ô û         | a e i o u           |
| ã õ               | a o                 |
| ç                 | c                   |
| ñ                 | n                   |
| ü                 | u                   |
| Ä Ö Ü (German)    | A O U               |
| Æ æ               | AE ae               |
| ß                 | ss                  |
| Ø ø               | O o                 |
| … and dozens more | see `normalizer.py` |

## Installation

```bash
# From the project root
pip install -e .
```

After installing, the `ig-normalizer` command becomes available system-wide (or in your active venv).

## Usage

```
ig-normalizer PATH [options]
```

### Options

| Flag                   | Description                                |
| ---------------------- | ------------------------------------------ |
| `--dry-run` / `-n`     | Preview changes without writing anything   |
| `--verbose` / `-v`     | Print every change to stdout               |
| `--no-rename`          | Skip renaming files/directories            |
| `--no-content`         | Skip fixing file contents                  |
| `--no-recursive`       | Only process top-level folder              |
| `--test STRING` / `-t` | Normalize a single string and print result |
| `--version`            | Show version                               |

### Examples

```bash
# Safe preview — see what would change
ig-normalizer /mnt/psp/textures --dry-run --verbose

# Fix everything recursively (rename files + fix .ini contents)
ig-normalizer /mnt/psp/textures

# Fix only .ini contents, keep filenames as-is
ig-normalizer /mnt/psp/textures --no-rename

# Fix only filenames, don't touch file contents
ig-normalizer /mnt/psp/textures --no-content

# Non-recursive — only the top folder
ig-normalizer /mnt/psp/textures --no-recursive

# Quick test of the normalization logic
ig-normalizer --test "Atlético MG / Goiás / São Paulo / Criciúma"
# Output: 'Atletico MG / Goias / Sao Paulo / Criciuma'
```

## Text file extensions recognized

`.ini .cfg .txt .csv .json .xml .yaml .yml .properties .conf .log .md .rst .bat .sh .html .htm .css .js .ts .py`

Binary files are automatically skipped.

## How it works

1. **Extra replacements** — ligatures and typographic characters that don't decompose cleanly (æ → ae, ß → ss, em-dash → -, etc.)
2. **NFKD decomposition** — splits combined characters into base letter + combining accent
3. **ASCII encode/ignore** — strips all remaining non-ASCII combining marks

This is a pure-stdlib solution — **no third-party dependencies required**.
