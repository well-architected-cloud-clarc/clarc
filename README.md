# clarc

A cloud-specific diagramming tool built on c43-layout.

- `--aws` (default) and `--azure` choose the theme and guide the nature of services (data vs non-functional).
- Input comes from `--file`, where `-` means stdin, to support piping.
- Output is drawio XML on stdout, to support piping.
- The input combines the node graph and hints. The main hint is which node is left-most; usually there is only one.
- An `example-json` sub-command prints an example input an LLM can use as inspiration: 2-4 nodes, 2-3 connections, a hints section with two elements, followed by a list of all possible hint directives.
- The reference architectures are the phase1 and phase2 diagrams of https://github.com/dooreelko/ghosted. They need not be reproduced 1:1, but better is not wrong. The first scope is AWS for those two references plus a hypothetical Azure replica.
