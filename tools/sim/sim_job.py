#!/usr/bin/env python3
"""Compatibility entry point; job orchestration is owned by tools/checks/sim_job.py."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.checks.sim_job import main  # noqa: E402

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
