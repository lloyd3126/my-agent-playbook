# Installation lifecycle

## Installation forms

1. Codex marketplace: registered from the GitHub repository and cached by Codex. Updating uses the official marketplace commands.
2. Git checkout: repository files are editable. Updating is allowed only with a clean worktree and a fast-forward from "origin/main".
3. Portable Release ZIP: the repository is a self-contained skill workspace. Managed files are recorded in `MANIFEST.sha256`; updater backups and optional user-local data live below `.local/`.

## Update invariants

- A check does not mutate files or Codex configuration.
- An apply operation verifies provenance before replacement.
- API keys, cookies, credentials, personal data, and `.local/` never enter an update archive or backup of managed files.
- Modified managed files stop a portable update for Agent review.
- Portable updates verify both the release ZIP checksum and its internal manifest.
- Obsolete managed files may be removed only after a backup is written inside `.local/playbook-manager/backups/`.
- Update failures leave user data in place and report the exact failed check.

## Removal invariants

- Preview is the default.
- Removing a Codex plugin does not remove a separate Git checkout or Release ZIP.
- Git and portable modes install no research runtime outside the repository. Inspect `.local/`, preserve anything requested, then move the exact repository folder to Trash after confirmation.
- Never self-delete from the manager script and never target a home directory or broad parent.
