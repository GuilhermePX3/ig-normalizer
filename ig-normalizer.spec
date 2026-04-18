# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec for ig-normalizer
# Build command (run inside the project root on Windows):
#   pyinstaller ig-normalizer.spec

import sys
from pathlib import Path

block_cipher = None

a = Analysis(
    ['src/ig_normalizer/cli.py'],
    pathex=[str(Path('src').resolve()), str(Path('src/ig_normalizer').resolve())],
    binaries=[],
    datas=[],
    hiddenimports=[
        'ig_normalizer',
        'ig_normalizer.cli',
        'ig_normalizer.normalizer',
        'unicodedata',
        'normalizer',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='ig-normalizer',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,          # console app (runs in cmd/terminal)
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    # icon='assets/icon.ico',  # uncomment and add an .ico if desired
)
