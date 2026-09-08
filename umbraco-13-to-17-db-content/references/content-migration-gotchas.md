# Content migration gotchas

The three weird content-side bugs that catch every v13 → v17 upgrade. Each has a known workaround.

## 1. The "visible state" bug

**Symptom:** After migration, blocks that were visible on v13 render as hidden on v17. Common
example: nav items disappear, sidebar widgets vanish, hero sections don't show.

**Root cause:** In v13, a block's `"visible"` property could be `""`, `"1"`, or `"0"`:
- `""` (empty) → treated as visible
- `"1"` → visible
- `"0"` → hidden

In v17, `""` is treated as hidden. So any v13 block with `"visible": ""` migrates to a hidden state.

**Fix:** Run the v13-side `fix-visible-property.ps1` script **before** starting the upgrade.
Targets `uSync\v9\Content` (or wherever the v13 uSync content lives), replaces `"visible": ""` with
`"visible": "1"`, then re-import uSync on v13 and commit.

This is a **pre-flight** fix, not a post-upgrade fix. If you missed it and you're already on v17,
your options are:

- Manually toggle every affected block in the v17 backoffice (slow, error-prone)
- Roll back to v13, run the script, re-import, commit, then redo the v17 upgrade
- Write a v17-side equivalent of the script that targets the v17 uSync export and re-import

The pre-flight approach is by far the cleanest.

## 2. The content-rendering bug

**Symptom:** After the v17 site first boots against a v13 DB:

- First page load: homepage "almost looks right" but has visible/hidden items wrong (nav contains
  items that should be hidden, or vice versa)
- After site restart: most content is missing entirely
- Manually re-publishing each page fixes it for that page

**Root cause:** Something in the v17 migration pipeline is leaving published content in a stale
state. Re-saving each node forces it to re-publish into the v17 schema.

**Workaround:** Force a republish of every node by going through uSync:

1. Full uSync export from v17 (capture current state)
2. **Delete the home node** in the backoffice and clear it from the Recycle Bin
3. Run uSync **Import** — this recreates the home node and every descendant, which forces
   save/republish on every single one
4. Verify the site renders correctly afterwards

This is heavy-handed but reliable. The manual alternative — re-publishing each page through the
backoffice — works on small sites but is impractical on anything with 100+ pages.

**Why not just re-publish from the root?** Re-publishing the root in the backoffice publishes the
home node but doesn't reliably cascade. Deleting + re-importing via uSync is what actually triggers
a fresh save on each individual node.

## 3. The 3rd-party data type re-link

**Symptom:** A data type shows the error "Property editor with alias 'X' is not available" in the
backoffice. Properties using that data type don't render on the frontend.

**Root cause:** The 3rd-party package shipped a new property editor alias in its v17 release.
Existing data types still reference the old alias.

**Canonical example: HubSpot Form Picker.** v13 used one alias; v17 uses a different one. The data
type uSync file needs updating.

**Fix:**

1. Open `uSync/v17/DataTypes/<datatype-name>.config`
2. Find the `<EditorAlias>` element
3. Replace the old alias with the new one (consult the package's release notes)
4. Re-import uSync

After re-import, the data type resolves correctly and properties using it render.

**Discovery process for unknown packages:** Open the package's NuGet release notes for v17 — they
usually call out alias renames. If not documented, install the package on a fresh v17 site and
inspect the data type it creates.

## Cross-cutting principle

These three bugs share a pattern: **what worked silently in v13 becomes a no-op in v17 because of
stricter handling**. Empty strings become hidden. Stale published states become missing content.
Misaligned property aliases become missing data types.

When troubleshooting other "looks fine on v13, missing on v17" symptoms, look for the same shape:
some convention in v13 that depended on lenient interpretation now needs to be made explicit.
