fix:

- A same-row hint between two nodes that are both in groups is dropped.
- Nodes with no data edge ignore rightOf, leftOf and sameCol.

----- AI agent updates -------

## Specification (clarified)

Placement hints are suggestions honoured when possible; the engine (c43-layout) applies them, clarc only passes them through. Two gaps make hints that look valid do nothing. Both were found on ghost/phase3/phase3.compact.clarc.json, where the hints `mailgun sameRow dlq`, `deploy sameCol content` and `sns rightOf cw` could not be honoured. The engine change lands in c43-layout (commit messages `[c43-layout][hs412]`); clarc gets a pin bump, regenerated goldens if any layout moves, and the hint wording in its agentic help.

### Meaning of the hint relations (unchanged)
- `rightOf`/`leftOf`/`above`/`below`: strictly later/earlier column or row, not adjacent; `sameRow`/`sameCol`: the cells share a row or column. `rightOf` alone never implies the same row. Rejected: giving the relations "adjacent" or "level with" semantics; users who want alignment say `sameRow`/`sameCol`.

### Gap 1: same-row between nodes in different groups
- Today: each group is laid out as its own block and the blocks are then placed on one grid. A node lines up with a node in a sibling block only when it is itself ungrouped. When both nodes are inside (different) groups the hint is dropped and reported as ignored; where the rows happen to coincide it only holds by luck (a neighbouring hint can break it).
- Wanted: a same-row hint between two nodes whose enclosing groups differ is honoured. After the blocks are placed, the node moves within its own block's row span onto the row of its peer (peers lined up with it follow), exactly the way an ungrouped node already does. If the peer's row lies outside the node's block, the block may grow to reach it when that does not push other hinted nodes off their hints; otherwise the hint stays reported as ignored.
- Nodes in the same group keep being handled by that group's own layout, which already honours above/below/sameRow.

### Gap 2: nodes without a data edge ignore leftOf, rightOf and sameCol
- Today: a node that has no data edge (only non-functional edges, or no edge at all) is not part of the column layering; it is put in the bottom band, in the column of the node it is connected to (or column 0 when it has no edge), and only the row relations (above, below, sameRow) are applied to it afterwards. So `sns rightOf cw` leaves the alarm topic under CloudWatch, and an unconnected `deploy sameCol content` goes to the bottom-left corner while `below content` holds for any lower row.
- Wanted: the hints of such a node decide its column and row, in this order of authority: an explicit hint to a placed node beats the edge anchor, which beats the default.
  - `sameCol X`: the column of X; `rightOf X`/`leftOf X`: the nearest free column right/left of X; `above`/`below X`: the nearest free row above/below X in the column given by the other hints, else X's column; `sameRow X`: X's row, nearest free column.
  - Several hints combine: `below content` + `sameCol content` puts it directly under content; `rightOf cw` + `sameRow cw` right next to CloudWatch.
  - A hint that cannot be satisfied (cell taken, conflicting hints) falls back to the edge anchor and is reported ignored. Cycles between hinted secondary nodes are resolved by hint order, the rest are ignored.
- Hinted nodes stay where the hints put them: the gravity step that moves nf-only top-level nodes down and right already skips hinted nodes and must keep doing so.
- Rejected: pulling these nodes into the data layering (it would give them layering edges and shift data columns); making `rightOf` on a secondary node move its source.

### Tests
- Engine cases (breaks before, green after): a grouped node with sameRow to a node in another group ends on its row; an unconnected node with `sameCol`+`below` sits right under its target; an nf-only node with `rightOf` sits right of its anchor; the combined case; hints that cannot be satisfied are still reported ignored.
- The compact phase3 diagram (clarc input in ghost) renders with no ignored placement hints once its hints are written as the author means them (Mailgun level with the dead-letter queue, deploy bucket under the content bucket, alarm topic right of CloudWatch).
- Existing goldens may move only where a node had such a hint; regenerate them and say which.

### Implementation notes (done in c43-layout, branch hs412-moar-hints)
- Gap 2: a node without data edges gathers the hints that tie it to nodes already placed (a hint pointing at it counts, read the other way round) and applies them in hint order; a hint that contradicts an earlier one is skipped. Column hints (sameCol, rightOf, leftOf) give a column range and beat the edge anchor, bounds included; the node takes the free cell nearest to the peer inside that range. sameRow gives the first row to look at; below gives it only together with a column hint, because a lone below is already handled when rows are applied and must not move nodes that were fine (the phase2 reference diagram would otherwise change).
- Gap 1: after a level's blocks are placed, the subject of a same-row hint between nodes of two different sibling groups moves within its block's row span onto its peer's row, swapping with whoever sits there; kept only when it leaves fewer violated hints. Decision on the open question: the block does not grow to reach a row outside its span; the hint stays reported as ignored.
- Found while testing the phase3 compact diagram: two ungrouped nodes lined up (same-row) with the same node competed for one cell and the second one was pushed to another row, out of reach. Now the second takes the next free cell of the shared row (to the right) when the occupant is lined up with the same node.
- Hint wording: clarc's agentic help says the directives also place nodes without data edges and nodes of different groups.

### Verification
- c43-layout engine tests (fail before, pass after): edge-less node with sameCol + below; nf-only node with rightOf + sameRow; nf-only node with leftOf left of its own source; contradicting hints on one node (reported once, the first one wins); same-row between members of two side-by-side groups; two nodes lined up with one node.
- Ghost phase3 compact diagram (the current input): no ignored hints (Mailgun level with the dead-letter queue, SMTP provider level with the data bucket, deploy bucket directly under the content bucket, alarm topic right of CloudWatch); 26 crossings. Its engine snapshot (tests/cases/phase3-compact) was refreshed from that input, with an assertion of no ignored hints and at most 30 crossings.
- clarc reference diagrams (phase1, phase2, azure-phase2): output unchanged.

### Observed, handed over
- A sameCol hint between two ungrouped data nodes fed from different child groups is not honoured in some nesting shapes (`smtp sameCol mailgun` in the compact phase3 diagram). Not caused by this task; it has its own task in c43-layout (asudd) with the minimal repro.

### Done
- c43-layout merged to main and pushed; clarc pins that commit, its help wording is committed, and the installed binary (~/.local/share/clarc/clarc) is built from the pinned sources. Ghost's diagrams are re-rendered by whoever owns that repo's current edits; this task leaves them alone.
