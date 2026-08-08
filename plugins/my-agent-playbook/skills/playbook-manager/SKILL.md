---
name: playbook-manager
description: Inspect, safely update, diagnose, or remove My Agent Playbook across a Git checkout, Codex marketplace installation, or portable Release ZIP. Use when a user asks whether the skills are current, wants Codex to self-update, needs installation health, or wants complete removal.
---

# Playbook Manager

Detect the installation mode and use the matching update lifecycle. Checks are read-only; mutations require the user's explicit request and "--apply".

## Inspect

~~~bash
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py status
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py update
~~~

For an installed plugin cache, execute the script using the skill's absolute path. Report the detected mode, current version, update availability, dirty files, and preserved data boundary.

## Update

- Git checkout: require a clean worktree, fetch "origin/main", and allow only a fast-forward pull.
- Codex plugin: run the official marketplace upgrade, then refresh "my-agent-playbook@my-agent-playbook".
- Portable ZIP: download the latest GitHub release, verify the ZIP checksum and internal manifest, refuse modified managed files, back up old managed files, and preserve the entire ".local/" tree.

~~~bash
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py update --apply
~~~

After code or plugin updates, tell the user to start a new Codex task or reload the workspace so skill discovery uses the new snapshot. Never silently schedule or background an update.

## Remove

Preview first:

~~~bash
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py uninstall
~~~

For a Codex installation, `--apply` removes the plugin; `--remove-marketplace` also removes its marketplace registration. For Git/portable mode, the manager reports the exact repository root and whether `.local/` exists; it does not delete its own folder.

For complete Git/portable removal, inspect `.local/`, decide whether anything must be copied out, then obtain explicit confirmation before moving that exact repository folder to Trash. There is no media runtime in My Agent Playbook v0.3.0+. Video workflows belong to Xeruca Player.

Read [references/lifecycle.md](references/lifecycle.md) before changing updater behavior or release layout.
