"""The public wait command must honor Actions even when failed results exist."""

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


class SimWaitTests(unittest.TestCase):
    def run_wait(self, states, passes):
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            state = temporary / "states.json"
            state.write_text(json.dumps(states))
            scripts = {
                "gh": """#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
if sys.argv[1] == 'auth':
    sys.exit(0)
p = Path(os.environ['WAIT_STATES'])
states = json.loads(p.read_text())
value = states.pop(0) if len(states) > 1 else states[0]
p.write_text(json.dumps(states))
print(json.dumps({'workflow_runs': [value]}))
""",
                "git": '#!/bin/bash\n[ "$1" != rev-parse ] || echo test-result-commit\nexit 0\n',
                "tar": """#!/usr/bin/env python3
import os, sys
from pathlib import Path
out = Path(sys.argv[sys.argv.index('-C') + 1])
(out / 'summary.json').write_text(os.environ['WAIT_SUMMARY'])
""",
                "sleep": "#!/bin/bash\nexit 0\n",
            }
            for name, source in scripts.items():
                executable = temporary / name
                executable.write_text(source)
                executable.chmod(0o755)
            run_id = "test-wait-" + temporary.name
            result = ROOT / "build/sim" / run_id
            try:
                return subprocess.run(
                    ["bash", "scripts/sim-run.sh", "--wait", run_id],
                    cwd=ROOT,
                    env={
                        **os.environ,
                        "PATH": f"{temporary}:{os.environ['PATH']}",
                        "WAIT_STATES": str(state),
                        "WAIT_SUMMARY": json.dumps({"passes": passes}),
                    },
                    capture_output=True,
                    text=True,
                    timeout=10,
                )
            finally:
                shutil.rmtree(result, ignore_errors=True)

    def state(self, status, conclusion=None):
        return {"status": status, "conclusion": conclusion, "html_url": "https://example.test/run"}

    def test_published_results_wait_for_failed_actions_conclusion(self):
        done = self.run_wait([self.state("in_progress"), self.state("completed", "failure")], False)
        self.assertEqual(done.returncode, 1, done.stdout + done.stderr)
        self.assertNotIn("DONE", done.stdout)
        self.assertIn("results:", done.stdout)

    def test_success_requires_actions_and_summary_success(self):
        for passes in (False, True):
            done = self.run_wait([self.state("completed", "success")], passes)
            self.assertEqual(done.returncode, 0 if passes else 1, done.stdout + done.stderr)
