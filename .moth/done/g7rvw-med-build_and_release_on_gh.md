subj

now just the linux, macos and windows binaries with the later goal of having a packaged agentic skill

the job should use project's nix

----- AI agent updates -------

## Decisions

- Goal: every push to `main` publishes ready-to-run clarc binaries on GitHub Releases. Packaging as an agentic skill is a later, separate goal; this task only produces the binaries.
- Trigger: push to `main` (rolling release). Also build+test (no publish) on pull requests. Rejected: tag-driven releases, manual dispatch only.
- Gate: a test job (`cargo build --release` + `cargo test`, linux) must be green before any release build starts.
- Nix: all jobs run their cargo commands inside the project's nix environment, not a runner-installed toolchain. A slim `ci.nix` (rust toolchain, plus the windows cross toolchain) is the single source of the build environment; `shell.nix` includes it (nix `import`, shell composed via `inputsFrom`) and adds only developer extras: moth and the drawio CLI (needed by `scripts/render.sh`). Rejected: using the old `shell.nix` in CI (heavy, needs github flakes), plain rustup per OS, a duplicated toolchain list in two files.
- `shell.nix` cleanup (part of this task): remove podman and its compat/setup machinery, terraform, tea, and the now unused nodejs — clarc is a plain cargo project and needs none of them. Keep moth and drawio-headless.
- Targets: linux x86_64 (gnu), linux aarch64, macOS aarch64, macOS x86_64, windows x86_64. Nix is used everywhere it can run: linux targets build natively on linux runners (x86_64 and arm); macOS targets build natively on macOS runners with nix installed there; windows is cross-compiled from linux inside nix with the mingw-w64 toolchain, so its target is `x86_64-pc-windows-gnu`. Rejected: windows msvc (cannot be built inside nix without MS SDK download), musl/static, windows arm, 32-bit.
- Runner specifics learned from the first real runs: macOS ships bash 3.2 which nixpkgs refuses, so jobs point `NIX_BUILD_SHELL` at a nix-provided bash (exposed by `ci.nix`); the arm macOS runner is pinned to an explicit image (`macos-15`) because the floating `macos-latest` label was never acquired by a hosted runner; the intel macOS runner is `macos-15-intel`; linux aarch64 uses the hosted arm runner `ubuntu-24.04-arm`.
- Release shape: a single moving prerelease tagged `latest`. Each run replaces the previous release and its assets (the tag is moved to the pushed commit). Rejected: one release per push (accumulates clutter), version-derived tags.
- Assets: one archive per target, named `clarc-<short-sha>-<target>` (`.tar.gz`; `.zip` on windows) containing the binary, LICENSE, README and the font license (`media/fonts/LICENSE-elms-sans.txt`). Plus one `SHA256SUMS` file covering all archives. Release notes state the commit sha.
- Portability: binaries built in nix reference the nix store. Linux binaries get their interpreter reset to the distro default and their rpath removed (patchelf, provided by `ci.nix`); macOS binaries get nix-store dylib references rewritten to `/usr/lib` and are ad-hoc re-signed. Each job fails if any `/nix/store` reference remains.
- No runtime files needed beside the binary: fonts and glyph catalogs are compiled in, drawio output is self-contained.
- Dependencies are fetched over https from public repos (c43-layout git rev pin), so the workflow needs no secrets beyond the default `GITHUB_TOKEN` with `contents: write` for the publish step only.
- Concurrency: a newer push cancels an in-flight older run so `latest` never ends up older than main.

## Implementation (abstract)

- `ci.nix`: minimal shell with rust toolchain (plus the mingw-w64 cross toolchain and the windows rust target for the cross build); `shell.nix` imports it and adds moth and drawio.
- One GitHub Actions workflow: `test` job -> matrix `build` jobs (nix-shell release build per target, archive, upload as artifacts) -> `publish` job (download all artifacts, compute checksums, recreate the `latest` prerelease with `gh`).
- While proving the workflow on a feature branch, that branch may be temporarily added to the push trigger (it then publishes `latest` from the branch); it is removed before merging so only `main` publishes.
- PR runs execute only the `test` job.
- Native binaries are smoke-checked (`clarc --agentic-help`, linux ones inside a plain debian container) before archiving; the windows exe is only checked for existence/PE format since it cannot run on the linux builder.



