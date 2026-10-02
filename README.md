# Umbraco 13 → 17 upgrade skills

An unopinionated set of AI skills to assist with upgrading from Umbraco 13.x to 17.x.

This repo contains five agent skills that guide an AI coding assistant through upgrading from
Umbraco 13 (.NET 8) to Umbraco 17 (.NET 10). They cover the build, the database and uSync
content, the backoffice, and the frontend views, including the known v17 migration bugs and
their fixes.

The skills use the open [Agent Skills](https://agentskills.io) format (a folder with a
`SKILL.md` file), so they work in any assistant that supports it: Claude Code, OpenAI Codex,
GitHub Copilot in VS Code, Cursor, Gemini CLI and others. Nothing in them is tied to one tool.

## The skills

| Skill | Use it for |
|---|---|
| `umbraco-13-to-17` | **Start here.** The overall upgrade order, and routing to the right sub-skill. |
| `umbraco-13-to-17-backend` | Getting the site to build and boot: `.csproj` → `net10.0`, NuGet packages, `Program.cs`, ModelsBuilder errors, `appsettings.json`. |
| `umbraco-13-to-17-database` | uSync export/fix/import, missing or hidden content, template import failures, data types. Includes two PowerShell fix scripts. |
| `umbraco-13-to-17-backoffice` | What editors see: RTE/TipTap config, BlockPreview, block labels, backoffice styles, YouTube embeds in the RTE. |
| `umbraco-13-to-17-frontend` | What visitors see: dictionary values, nested sections, Umbraco Forms templates. |

The skills point to each other by name, so **install all five together**.

## Install

Put the five `umbraco-13-to-17*` folders into your assistant's skills folder, either inside the
Umbraco project you're upgrading (only that project sees them) or in your home folder (every
project sees them).

| Assistant | Project folder | Personal folder |
|---|---|---|
| OpenAI Codex (CLI and IDE extension) | `.agents/skills/` | `~/.agents/skills/` |
| GitHub Copilot in VS Code | `.agents/skills/` or `.github/skills/` | `~/.agents/skills/` or `~/.copilot/skills/` |
| Cursor | `.agents/skills/` or `.cursor/skills/` | `~/.agents/skills/` or `~/.cursor/skills/` |
| Gemini CLI | `.agents/skills/` or `.gemini/skills/` | `~/.agents/skills/` or `~/.gemini/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |

`.agents/skills/` works for every tool above except Claude Code, so it's the best choice if your
team uses a mix. Check your tool's own docs if it isn't listed; most use one of these paths.

**macOS / Linux**, from the root of the Umbraco project:

```bash
git clone https://github.com/stayawakesteve/umbraco-upgrade-skills.git /tmp/umbraco-upgrade-skills
```

```bash
mkdir -p .agents/skills && cp -R /tmp/umbraco-upgrade-skills/umbraco-13-to-17* .agents/skills/
```

**Windows (PowerShell)**, from the root of the Umbraco project:

```powershell
git clone https://github.com/stayawakesteve/umbraco-upgrade-skills.git $env:TEMP\umbraco-upgrade-skills
New-Item -ItemType Directory -Force .agents\skills | Out-Null
Copy-Item -Recurse $env:TEMP\umbraco-upgrade-skills\umbraco-13-to-17* .agents\skills\
```

Swap `.agents/skills` for your tool's folder from the table if you need to. Restart the
assistant, or start a new chat, so it picks the skills up. In Gemini CLI, run `/skills reload`
and check they're enabled with `/skills list`.

To keep them up to date, clone the repo somewhere permanent and symlink the folders in instead
of copying.

## Using the skills

### Just describe what you're doing

You don't need to name a skill. Each one has a description of the situations it handles, and the
assistant loads the right one when your request matches. Mention **v13 and v17** (or "Umbraco
17") so it knows you're mid-upgrade, for example:

> We're upgrading this site from Umbraco 13 to 17. Where do I start?

> After the v17 upgrade, the Media library throws "Order by value is not a property on the
> configured collection".

> Umbraco 17 won't build: IPublishedSnapshotAccessor errors in the generated models.

> Our pages show dictionary keys like `footer.copyright` instead of text since moving to v17.

> Can I just copy our v13 Umbraco Forms templates into the v17 site?

Pasting the exact error message or symptom helps it pick the right skill and the right fix.

### Or ask for a skill by name

If the assistant doesn't pick a skill up, or you want a specific one:

| Assistant | How to call a skill |
|---|---|
| Claude Code | `/umbraco-13-to-17` |
| OpenAI Codex | `$umbraco-13-to-17` (or pick it from the skills selector) |
| GitHub Copilot in VS Code | `/umbraco-13-to-17` in chat |
| Cursor | Type `/` in Agent chat and search for the skill |
| Gemini CLI | Describe the task; it asks to activate the matching skill. `/skills list` shows what's installed. |

Add your question after the name, e.g. `/umbraco-13-to-17-database uSync import is failing on
templates`.

### Assistants without skill support

Any assistant that can read files in your project can still use these. Point it at the file:

> Read `.agents/skills/umbraco-13-to-17/SKILL.md` and follow it. We're starting a v13 → v17
> upgrade of this site.

It follows the links from there into the other skills and their reference files.

## How an upgrade runs

The starting skill (`umbraco-13-to-17`) walks you through this order. Doing the steps out of
order wastes time, e.g. exporting uSync from a site that doesn't build yet gives you stale data.

0. **Pre-flight, on v13.** Fix the "visible" block values in the v13 uSync content, branch off
   `main`, audit which packages have v17 versions, back up the database.
1. **Backend.** Retarget to .NET 10 and update packages until the site builds and boots.
2. **ModelsBuilder.** Rebuild the models on v17.
3. **Database and content.** Export uSync from v17, run the fix scripts, re-import, then
   force a republish.
4. **Backoffice and frontend.** Mostly separate files from step 3 and from each other, so a second
   person can work on them in parallel. The exception is the RTE data-type settings: they live in
   the uSync data type files that step 3 re-imports, so apply them after step 3's final import.
5. **Verify.** Work through the done checklist before merging.

If you're already part-way through, skip ahead: describe the symptom and the assistant goes
straight to the skill that fixes it.

## The PowerShell scripts

The database skill ships two scripts in `umbraco-13-to-17-database/scripts/`. The assistant
tells you when to run each one; you run them yourself, from the folder that contains your
`uSync` folder (usually the web project).

| Script | When | Works on |
|---|---|---|
| `fix-visible-property.ps1` | On the **v13** branch, before the upgrade | `uSync\v9\Content` |
| `fix-listview-orderby-casing.ps1` | On v17, after the uSync export | `uSync\v17\DataTypes` |

The folder paths are fixed inside each script, so check they match your project first. They need
PowerShell (built into Windows; install [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
on macOS or Linux and run them with `pwsh`). Commit before running them, so you can review the
changes as a diff.

## Good to know

- **They're for upgrades, not new builds.** For a new v17 site, start from a fresh Umbraco 17
  install or your boilerplate of choice.
- **The assistant doesn't run the whole upgrade on its own.** Package versions, uSync imports
  and the fix scripts all need a person watching and reviewing the diffs.
- **Each skill has an `evals/` folder.** These are test prompts for whoever maintains the skills.
  Assistants ignore them, and you can leave them out when installing.
