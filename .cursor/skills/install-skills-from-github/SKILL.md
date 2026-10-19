---
name: install-skills-from-github
description: >-
  Install Agent Skills from a GitHub repo into Cursor globally (every local
  agent, and Cloud VMs via the environment install hook). Use when the user
  pastes a GitHub skills repo URL, says "install these skills", "add this
  skill pack", "make these skills available everywhere", or asks to sync
  skill sources for Cloud Agents.
---

# Install skills from GitHub (Cursor global)

When the user gives a GitHub repo that contains Agent Skills (`SKILL.md`
files), install them for **all** Cursor agents on this machine and register
them for Cloud environment sync. Do the work yourself; do not only tell the
user which commands to run.

## What "everywhere" means

| Surface | How this installer covers it |
| --- | --- |
| Local Cursor Agents (any repo on this machine) | Copies into `~/.cursor/skills/` |
| Other Agent Skills harnesses | Also copies into `~/.agents/skills/` |
| Cloud Agent VMs using this environment | `sync` during environment `install` from `.cursor/skill-sources.txt` |

Cursor cannot push your laptop home directory into every Cloud VM. Cloud
coverage depends on this environment's `install` hook running
`.cursor/cloud-install-skills.sh`, and on other repos using this same Cloud
environment (or the same `skill-sources.txt` + install hook).

## Steps (always)

1. Confirm the URL is a GitHub repo (`https://github.com/owner/repo` or
   `owner/repo`). If it is not, stop and say so.
2. From the repo root that contains this installer, run:

```bash
bash scripts/install-cursor-skills-from-github.sh add '<github-url>'
```

   Optional pin:

```bash
bash scripts/install-cursor-skills-from-github.sh add '<github-url>' --ref main
```

3. Run `list` and show the user which skill names landed:

```bash
bash scripts/install-cursor-skills-from-github.sh list
```

4. Commit `.cursor/skill-sources.txt` if it changed (the `add` command
   appends the slug there). Push when you are already committing other work,
   or when the user wants Cloud rebuild coverage.
5. Tell the user clearly:
   - Local Agents can use the new skills in the **next** Agent chat.
   - Cloud VMs pick them up after they **Save** an environment that runs
     `.cursor/cloud-install-skills.sh` on `install`, then start a **new**
     agent from a successful build (or after you trigger/propose that
     install for them).

## Other commands

```bash
bash scripts/install-cursor-skills-from-github.sh sync
bash scripts/install-cursor-skills-from-github.sh remove '<github-url|owner/repo>'
```

`sync` re-fetches every source in `.cursor/skill-sources.txt` plus
`~/.cursor/skill-sources.json`. Use it after editing the checklist by hand,
and from Cloud `install`.

## Cloud environment install (required for VM coverage)

The environment `install` command must include:

```bash
bash .cursor/cloud-install-skills.sh
```

If that hook is missing, add or propose it. Do not put long-running servers
in `install`; this script must exit.

## Rules

- Prefer running the script over re-implementing clone/copy logic.
- Do not `git clean` or permanently delete existing skill folders; the
  installer moves replaced installs under `~/.cursor/skills-removed/`.
- If egress blocks `github.com`, say that Cloud install cannot fetch packs
  until the domain is allowed.
- Do not install both a managed plugin copy and a skills.sh/global copy of
  the same pack without warning about duplicates.
