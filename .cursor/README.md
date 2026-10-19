# Cursor global skills

This folder wires **GitHub skill packs** into every Cursor Agent that uses
this machine or this Cloud environment.

## Quick use

Give an agent a GitHub skills repo URL (or run it yourself):

```bash
bash scripts/install-cursor-skills-from-github.sh add https://github.com/owner/skills-repo
```

That:

1. Clones the repo into `~/.cursor/skill-cache/`
2. Copies every `SKILL.md` skill into `~/.cursor/skills/` (and `~/.agents/skills/`)
3. Appends the repo to `.cursor/skill-sources.txt` and `~/.cursor/skill-sources.json`

## Cloud Agents

Set the environment **install** command to:

```bash
bash .cursor/cloud-install-skills.sh
```

List packs in [`skill-sources.txt`](./skill-sources.txt). Rebuild the
environment after you change that list so new VMs get an updated snapshot.

Attach this same Cloud environment to other repos if you want those Cloud
Agents to inherit the same global skills.

## Agent skill

[`.cursor/skills/install-skills-from-github`](./skills/install-skills-from-github/SKILL.md)
teaches agents to run the installer when you paste a repo link.
