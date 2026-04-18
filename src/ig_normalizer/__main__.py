"""Allow running as: python -m ig_normalizer"""
import sys

# Absolute import — works both as a package and when bundled by PyInstaller
try:
    from ig_normalizer.cli import main
except ImportError:
    from cli import main  # PyInstaller one-file fallback

sys.exit(main())
