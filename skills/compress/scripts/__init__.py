"""Terse compress scripts.

Local, no-LLM helpers for /terse compress: file-type detection and
structural validation. The compression itself is done inline by the
acting agent (Read -> compress -> Edit), not by these scripts.
"""

__all__ = ["cli", "detect", "validate", "benchmark"]

__version__ = "1.0.0"
