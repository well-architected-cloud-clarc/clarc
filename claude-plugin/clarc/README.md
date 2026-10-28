# clarc plugin

Draws cloud (AWS or Azure) architecture diagrams as drawio files. The `clarc` skill writes a JSON service graph from your project's code or from a discussion with you, runs the `clarc` tool, and shows the result; you then steer the layout in plain words until it is right. Layout, routing and styling are done by clarc, not by hand.

Use it by asking for an architecture diagram, or with `/clarc:clarc <what to draw>`.

## What the skill does on your machine

- Reads files of the project you point it at (IaC, docs) to learn the architecture.
- Writes `<name>.clarc.json` and `<name>.drawio` (and a PNG, see below) into that project.
- Runs `clarc` to turn the JSON into drawio XML.
- Runs the drawio CLI to make a PNG preview, only if `drawio` is already on PATH. The skill never installs it; without it you get the `.drawio` file to open in drawio.

## The clarc binary

The skill needs the `clarc` executable and finds it in this order:

1. `clarc` on PATH.
2. A copy cached at `~/.local/share/clarc/clarc`.
3. A download: `scripts/ensure-clarc.sh` fetches the archive for your OS and CPU from the rolling `latest` release of https://github.com/well-architected-cloud-clarc/clarc and checks its SHA-256 against the `SHA256SUMS` file of the same release, then caches it as above.

The checksum guards against a corrupt download, not against a compromised release, because both files come from the same place. To avoid the download, build clarc yourself (`cargo build --release` in the repo) and put it on PATH; to refresh a cached copy, delete it.

## Links

- Source, tool documentation and demo: https://github.com/well-architected-cloud-clarc/clarc
- License: MIT
