let's have an option (off by default for now) to join inbound and oubound ports if there are more than 2 on the same side.
the possible hints are (applied to all nodes)
- join all ports (each node will have only one inbound and one outbound port)
- join all crowded inbound ports (if >2, all inbound ports on the same side will become one)
- join all crowded outbound ports


----- AI agent updates -------

## Decisions

- Feature: an option that merges the ports of a node side into one, to calm nodes with many edges. Off by default (existing output, goldens unchanged).
- Surface: top-level field of the clarc input document, `joinPorts` (string, unknown value is an input error). Rejected: CLI-only flag (the skill, which writes the JSON, would need a second channel); both (no need now).
- Modes: `joinPorts` is one of `off` (default), `inbound`, `outbound`, `crowded`, `all`:
  - inbound: on every node side, if more than 2 inbound ports sit on it, they become one port.
  - outbound: the same for outbound ports.
  - crowded: both of the above (the in-between mode: collapse all crowded ports, keep sparse sides as they are).
  - all: join regardless of the threshold, so each node side has at most one inbound and one outbound port.
  - The engine takes these as combinable flags (inbound, outbound, all); `crowded` = inbound + outbound. Rejected: a CLI/JSON of independent booleans (one enum reads better for the skill).
- Applies to all nodes (not per node). Groups are not nodes: their border ports are left as they are.
- "Crowded" = more than 2 ports of one direction on one side of one node. Inbound and outbound are counted separately; a side with 2 inbound and 3 outbound joins only the outbound. In and out on one side stay distinct ports.
- A joined port is a single attachment point: the only slot of its side (so its middle), or, when the other direction also has ports there, one slot among them, placed where the first of its ports was. The edges keep their own routes (lanes/tracks) and converge at that point; arrowheads overlap there. Rejected: merging into a shared trunk before the port (needs routing merge logic).
- Joined ports count as one slot when sizing a node side and spreading slots, so a node with joined sides can be smaller.
- Joining is per side: when the engine already sends overflow outbound edges to another side (more than 3 data outs on the right), each side is judged and joined on its own, so a node can keep several outbound points on different sides.
- Placement is done on the original ports; joining happens after placement/repair (like port snapping), so it does not change where nodes go, only where edges attach.
- The renderer ends all joined edges at the same icon point, using the joined port's single slot.
- Home of the change: port assignment and geometry live in c43-layout (the engine must know the port is shared); clarc exposes the option and passes it through. c43-layout is a git dependency pinned by rev, so: c43-layout first on a feature branch, then clarc bumps the pin.
- `--agentic-help` documents `joinPorts` so the skill can use it.

## Implementation (abstract)

- Input: `joinPorts` (inbound / outbound flags, all) deserialised in clarc and forwarded to the engine as a graph-level option.
- Engine: after the search ends, a post-pass on the final port assignment groups ports per node, side and direction by the rule above; each group becomes one slot shared by its edges.
- Routing and track assignment treat a shared slot as the same endpoint for all its edges; geometry places it at the side's middle.
- clarc renderer: connection offsets use the shared slot; no other look change.
- Edges that meet at a joined port touch there by design, so the engine's rule check does not count crossings/overlaps between them.
- Tests: a hub node with 4 inbound and 3 outbound edges, checking the number of distinct attachment points on the hub for each mode (engine and clarc); sides with up to 2 ports are not joined by the crowded modes; joined layouts have no rule violations; an unknown mode is an input error; off mode equals the existing goldens.



- Delivery: c43-layout work merged to its main (`[clarc][rkf3w]` commits); clarc pins that rev. README documents `joinPorts`.
