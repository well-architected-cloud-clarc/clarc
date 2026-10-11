instead the shared parts should be in c43-layout

----- AI agent updates -------

## Decisions

- Goal: clarc depends on c43-layout only; the c43 crate is not a dependency of clarc any more (a diagram tool for cloud services must not pull in the TypeScript/C4 extraction stack).
- The shared part is the generic drawio emission: text measuring and wrapping (font/unit constants, `text_width`, `wrap`, label and edge-label line splitting), the header band (title and description above the frame), the exporter (`esc`, `vertex`, `Drawing`, `Styler`, `EdgeDraw`, `to_drawio`) and `render_styled` (layout + title/description + a caller-supplied `Styler` in, drawio XML out). They move into c43-layout as a `drawio` module; they depend on layout types only.
- Stays in c43 (needs the C4 document model): C4 document to graph building, roles/icons metadata and the pretty styling (`Styler` for roles), icon-file parsing, `render`, `render_with_hints`, `render_pretty`, `render_layout`. Since a foreign type cannot get inherent methods, the pretty styler becomes a free function in c43.
- c43 re-exports the moved modules under `c43::drawio` (`text`, `export`, `header`, `render_styled`), so existing c43 paths and tests keep working. Rejected: rewriting every c43 call site; moving the whole drawio module (would drag the C4 model into c43-layout).
- The move itself changes no output: c43 goldens are unchanged. Because clarc's pinned c43 was older than the moved code, adopting it changes clarc's header text cells in drawio from `whiteSpace=wrap` to `whiteSpace=nowrap` (lines are pre-wrapped by the renderer, so the look is the same); clarc goldens are regenerated for that and nothing else. The engine's `SizeHints` gained `title_bottom` (opt-in group title band at the bottom); clarc keeps it off.
- The moved entry points are public in c43-layout: `render_styled` (plain frame) and `render_with` (frame style given, used by c43's pretty look). Rejected: leaving the frame-style variant private and duplicating it in c43.
- Pins: c43-layout is consumed as a git dependency pinned by revision in both c43 and clarc; the dependency order is c43-layout first, then c43 and clarc. No local path overrides are committed.
- Delivery: work on feature branches in all three repos; commits in c43-layout/c43 carry `[proj][o96fn]`; git rev pins in c43 and clarc bumped to the new commits.

## Implementation (abstract)

- c43-layout gains `drawio` (text, header, export, `render_styled`), moved verbatim with its tests.
- c43 drops those sources, re-exports them from c43-layout, turns the pretty styler into a free function, pins the new c43-layout rev.
- clarc removes the `c43` dependency and imports the drawio pieces from c43-layout; lockfile no longer contains c43 or its parser stack.


