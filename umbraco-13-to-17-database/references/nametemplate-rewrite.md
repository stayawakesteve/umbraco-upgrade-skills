# `nameTemplate` AngularJS → UFM rewrite

In v13, block labels and `nameTemplate` fields used AngularJS template syntax. In v17, both use UFM
(Umbraco Flavored Markdown).

## What needs migrating

Anywhere a template string uses AngularJS expressions like `{{ ... }}` with helpers like
`ncNodeName`. This appears in:

- **uSync data type configs** (`uSync/v17/DataTypes/*.config`) — the `nameTemplate` of Block List
  and Block Grid data types
- **Block labels** in the backoffice (these can be fixed via the UI or via the uSync files —
  doing it in the uSync files is faster for sites with lots of blocks)

## The transformation

| AngularJS                       | UFM                          |
|---------------------------------|------------------------------|
| `{{ heading }}`                 | `{$heading}` or `{heading}`  |
| `{{ value | ncNodeName }}`      | `{umbContentName: value}`    |
| `{{ value | take:50 }}`         | `{value:take:50}`            |
| `{{ value or 'fallback' }}`     | `{$value:fallback('fallback')}` |

The `$` prefix references a property.

UFM has its own filter syntax — get each filter from the Umbraco UFM docs rather than mapping
filter-by-filter from memory.

## Doing the rewrite

### Approach A: Edit uSync files directly

For each affected data type:

1. Open `uSync/v17/DataTypes/<datatype-name>.config`
2. Find the `nameTemplate` value
3. Rewrite to UFM
4. Save

Then re-import uSync.

A bulk find/replace works for common patterns:

```
Find:    "nameTemplate":\s*"\{\{\s*value\s*\|\s*ncNodeName\s*\}\}"
Replace: "nameTemplate": "{umbContentName: value}"
```

But the more interesting templates have property-specific expressions that need manual review.

### Approach B: Edit in the backoffice UI

After uSync import, go through each Block List / Block Grid data type and update the label / name
template in the backoffice. Slower but lets you see the live result as you go.

Recommended approach: **do the bulk patterns via files (approach A), then walk the data types in
the backoffice (approach B) to clean up anything the bulk replace missed**.

## Verifying

After the rewrite:

1. Open a Block Grid data type in the backoffice — labels for each block should render correctly
2. Open a content node using the data type — block labels in the editor should show real values
   (not the literal template syntax)
3. Search the uSync files for `{{ ` — there shouldn't be any matches in `Content/` or `DataTypes/`
   folders if the rewrite is complete
