# Umbraco 13 → 17 Skills Bundle

Five skills for upgrading Etch CMS sites from Umbraco 13 to v17:

- **`umbraco-13-to-17/`** — router / orchestrator
- **`umbraco-13-to-17-backend/`** — .csproj, Program.cs, namespaces, build errors
- **`umbraco-13-to-17-database/`** — uSync, content migration, includes 3 PowerShell scripts
- **`umbraco-13-to-17-backoffice/`** — editor-facing: RTE, block previews and labels, backoffice SCSS, backoffice CSP
- **`umbraco-13-to-17-frontend/`** — visitor-facing: tag helpers, dictionary values, views, Umbraco Forms, frontend CSP

Each skill includes its own `evals/evals.json` with 5–6 test prompts.

## To evaluate the skills (one-shot setup)

### 1. Drop your `skill-evals` skill folder in alongside these

Final directory layout:

```
this-folder/
├── skill-evals/                              ← your existing skill-evals folder
├── umbraco-13-to-17/
├── umbraco-13-to-17-backend/
├── umbraco-13-to-17-backoffice/
├── umbraco-13-to-17-database/
└── umbraco-13-to-17-frontend/
```

### 2. Sanity check

From this folder, run:

```bash
ls skill-evals/SKILL.md \
   skill-evals/eval-viewer/generate_review.py \
   umbraco-13-to-17-backend/SKILL.md \
   umbraco-13-to-17-backend/evals/evals.json
```

All four paths should resolve. If any error, fix that before continuing.

### 3. Start Claude Code in this folder

```bash
cd /path/to/this-folder
claude
```

### 4. Paste this prompt

```
Read ./skill-evals/SKILL.md and follow it to evaluate the skill at ./umbraco-13-to-17-backend
using the evals in ./umbraco-13-to-17-backend/evals/evals.json. Apply skill-evals' lean
defaults: no baseline runs this iteration, Haiku for grading, surface the eval viewer
when done.
```

Claude reads skill-evals, spawns subagents per eval prompt with the umbraco skill loaded,
grades, and opens the viewer. Review, give feedback, close.

### 5. Repeat for the other four skills

Same prompt with different paths:

```
Now do the same for ./umbraco-13-to-17
```

```
Now do the same for ./umbraco-13-to-17-backoffice
```

```
Now do the same for ./umbraco-13-to-17-database
```

```
Now do the same for ./umbraco-13-to-17-frontend
```

## Troubleshooting

**"No evals.json found"** → check `<skill>/evals/evals.json` exists. They're already in place
in this bundle but worth confirming if you've moved things.

**"Cannot find skill at path"** → the path is relative to where `claude` was started. Run
`pwd` to confirm you're in the parent folder.

**Viewer doesn't open** → check `skill-evals/eval-viewer/generate_review.py` exists. If your
`skill-evals` folder is missing the viewer, the skill can't surface results — re-unpack
the original `skill-evals.zip`.

**Eval refuses to run with a different error** → paste the error verbatim into a new Claude
conversation; that's usually enough to pinpoint it.

## Installing the skills (separate from evaluation)

If you want to **use** these skills (rather than evaluate them), each folder is a complete,
installable skill. Zip the folder and install via your usual Claude Code plugin/skill
mechanism, or drop the folder into your `.ai-standards`-equivalent skills location.

The bundled `evals/` directories don't interfere with normal skill use — they sit alongside
SKILL.md and are only read by skill-evals.

## What's in each skill

### `umbraco-13-to-17/` (router)
- SKILL.md, 2 reference files (pre-flight checklist, done checklist)
- No bundled scripts — the router delegates to sub-skills

### `umbraco-13-to-17-backend/`
- SKILL.md, 5 reference files:
  - `csproj-net10-retarget.md` — package list, centralised versioning
  - `program-cs-v17.md` — full v17 Program.cs shape with rationale
  - `modelsbuilder-fixes.md` — IPublishedSnapshotAccessor → IPublishedContentTypeCache
  - `appsettings-v17.md` — appsettings.json deltas vs v13
  - `razor-source-generator-fix.md` — CS8785 duplicate hintName error

### `umbraco-13-to-17-backoffice/`
- SKILL.md, 3 reference files:
  - `scss-and-partials.md` — blockpreview.scss, section partials, backoffice info colours, picker styles
  - `rte-config.md` — TipTap Word Count, toolbar, image sizing, Uploads folder
  - `blocks-and-pickers.md` — BlockPreview, UFM labels, backoffice info partials, YouTube CSP

### `umbraco-13-to-17-frontend/`
- SKILL.md, 3 reference files:
  - `taghelpers-migration.md` — `<our-X>` → `<etch-cms-X>` and GetDictionaryValueOrDefault
  - `views-and-csp.md` — nested-section BlockGrid fix, CIVIC cookie banner CSP
  - `umbraco-forms.md` — Forms template merge

### `umbraco-13-to-17-database/`
- SKILL.md, 4 reference files:
  - `usync-workflow.md` — full export-fix-import sequence
  - `content-migration-gotchas.md` — visible-state bug, republish workaround, 3rd-party data types,
    List View `orderBy` casing
  - `template-import-order.md` — `_layout.config` prefix trick
  - `nametemplate-rewrite.md` — AngularJS → UFM template syntax
- `scripts/` — three ready-to-run PowerShell scripts:
  - `fix-visible-property.ps1` (run on v13 side, pre-upgrade)
  - `transform-mntp-filter-udis-to-guids.ps1` (run on v17 side, post-export)
  - `fix-listview-orderby-casing.ps1` (run on v17 side, post-export)
