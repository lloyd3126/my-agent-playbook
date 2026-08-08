from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class PortableReleaseTests(unittest.TestCase):
    def test_release_archive_is_clean_and_has_portable_entrypoints(self) -> None:
        version = (REPO_ROOT / "VERSION").read_text(encoding="utf-8").strip()
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "dist"
            environment = dict(os.environ, PLAYBOOK_RELEASE_SOURCE="working-tree")
            subprocess.run(
                [str(REPO_ROOT / "scripts" / "build-release.sh"), str(output)],
                cwd=REPO_ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                env=environment,
                check=True,
            )
            archive = output / f"my-agent-playbook-v{version}-portable.zip"
            checksum = archive.with_suffix(archive.suffix + ".sha256")
            self.assertTrue(archive.is_file())
            self.assertTrue(checksum.is_file())
            with zipfile.ZipFile(archive) as bundle:
                names = bundle.namelist()
                prefix = f"my-agent-playbook-v{version}/"
                self.assertIn(prefix + "START-HERE.md", names)
                self.assertIn(prefix + "VERSION", names)
                self.assertIn(prefix + "MANIFEST.sha256", names)
                self.assertIn(prefix + ".agents/plugins/marketplace.json", names)
                self.assertIn(prefix + ".agents/skills/x-account-research/SKILL.md", names)
                self.assertIn(prefix + ".agents/skills/x-thread-publishing/SKILL.md", names)
                self.assertIn(prefix + ".agents/skills/statementdog-company-analysis/SKILL.md", names)
                self.assertIn(prefix + ".agents/skills/playbook-manager/SKILL.md", names)
                self.assertIn(prefix + "plugins/my-agent-playbook/.codex-plugin/plugin.json", names)
                self.assertFalse(any("scripts/portable/" in name for name in names))
                self.assertFalse(any("youtube-caption-library" in name for name in names))
                self.assertFalse(any("transcribe-media" in name for name in names))
                forbidden_parts = {".git", ".local", "dist", "__pycache__"}
                self.assertFalse(any(forbidden_parts.intersection(Path(name).parts) for name in names))
                self.assertFalse(any(name.endswith((".mp4", ".pt", ".pyc", ".pyo")) for name in names))


if __name__ == "__main__":
    unittest.main()
