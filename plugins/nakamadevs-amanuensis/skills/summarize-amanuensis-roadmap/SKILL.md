---
name: summarize-amanuensis-roadmap
description: Generate or refresh a self-contained visual HTML primer from the Amanuensis Markdown roadmap. Use when someone wants a roadmap summary, a visual explanation of completed versus missing work, a planning overview, an onboarding primer, or an updated docs/ROADMAP_PRIMER.html after roadmap changes.
---

# Summarize the Amanuensis roadmap

Create a deterministic, accessible HTML view of what is delivered, what remains, and what is deferred.

## Generate

1. Read `docs/ROADMAP.md`; audit it first with `$audit-amanuensis-roadmap` when the user also asks whether its status is current.
2. Run:

   ```sh
   python .agents/skills/summarize-amanuensis-roadmap/scripts/render_roadmap_primer.py \
     docs/ROADMAP.md docs/ROADMAP_PRIMER.html
   ```

3. Keep the generated file self-contained: no remote fonts, scripts, images, analytics, or network requests.
4. Do not hand-edit generated HTML. Change the Markdown source or renderer and regenerate it.

## Explain

Use the primer's three levels consistently:

- `Completado`: checked roadmap work;
- `Por hacer`: unchecked committed work;
- `Después`: unchecklisted backlog ideas that are not current commitments.

Keep product decisions and expected outcomes near their sections. Never imply that the percentage is a delivery estimate; it is only the share of explicit checklist items marked complete.

## Validate

Run both commands:

```sh
python .agents/skills/summarize-amanuensis-roadmap/scripts/render_roadmap_primer.py \
  docs/ROADMAP.md docs/ROADMAP_PRIMER.html --check
```

Confirm the counts match the audit inventory, every open item appears in `Qué falta`, backlog remains separate, the layout works at narrow widths, and headings and progress elements have accessible labels.

## Deliver

Summarize the most important completed capabilities, immediate gaps, and later backlog. Link both `docs/ROADMAP.md` and `docs/ROADMAP_PRIMER.html` so readers can move between source and primer.
