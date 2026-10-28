---
description: Always use when the user asks to create, generate, draw or update a cloud architecture diagram (AWS or Azure), or a diagram of a project's cloud infrastructure.
---

# clarc: cloud architecture diagrams

You write a JSON service graph; `clarc` does layout, routing, theming and drawio output. Never place anything by hand.

`$ARGUMENTS` is what to draw (a project path, a phase, a component) and optionally layout wishes. Default theme is AWS; use `--azure` for Azure.

## 1. Get clarc

```bash
CLARC=$(bash "${CLAUDE_SKILL_DIR}/scripts/ensure-clarc.sh")
```

Uses `clarc` from PATH, else downloads (checksum-verified) the `latest` GitHub release into `~/.local/share/clarc`.

## 2. Learn the input format

Run `$CLARC [--azure] --agentic-help` and follow it: example JSON, hint directives, glyph names, edge kinds. Do not rely on memory of the format.

## 3. Collect the facts

Pick the mode from the request; ask if unclear.

- **Discover from code**: read the target project (IaC, docs, specs, existing diagrams) and model what is there.
- **Generate from a discussion**: for an architecture that doesn't exist yet (or isn't in code), ask the user what the parts are and how they talk, then play the model back (nodes, groups, flows) and get a go-ahead before rendering.
- Both can be mixed: discover, then adjust by discussion.

Use only what the sources or the user give; don't invent components. Ask when something is unclear.

- node = a deployed service or external party; group = a boundary (network, region, account)
- edge = data flow by default; mark DNS, monitoring/alarms, identity/role assumption, configuration/secrets, image pull as `"kind": "nf"`
- show the fully deployed state, ignore feature flags
- never put secrets, ARNs or account ids into labels

## 4. Render a first version

Write the JSON next to the project's docs (e.g. `<name>.clarc.json`), then:

```bash
$CLARC --file <name>.clarc.json > <name>.drawio
drawio -x -f png -s 2 -o <name>.png <name>.drawio --no-sandbox   # only if `drawio` is on PATH
```

Set only the `start` hint (usually the client) up front. Fix errors and warnings on stderr yourself (unknown glyph → use a suggestion). Show the user the PNG; without the drawio CLI, tell them to open the `.drawio` in drawio.

## 5. The user drives the layout

Translate each wish into `hints` ("X left of Y" → `"x": {"leftOf": "y"}`), regenerate, show again. Repeat until the user accepts. Don't tune the layout for looks on your own.
