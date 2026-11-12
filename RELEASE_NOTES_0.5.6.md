# ForeverFlow 0.5.6 — Approved Test 10

**Approved by the addon owner:** November 12, 2026.  
**Publishing status:** Approved release candidate; the GitHub `release` branch and CurseForge must not be considered updated until the approved Test 10 sources, media and automation have been synchronized and the publish workflow succeeds.

## Release changes

- Six-tab redesigned ForeverFlow interface: Today, Leveling, Gold, Skills, Character and Settings.
- Floating guide with native bottom-right resizing, preserved top-left anchoring, per-character saved dimensions, and controls attached to the guide edges.
- Expanded quest discovery and route advice using live client data plus explicitly labeled reported pickup coordinates.
- Profession coaching, recipe and materials planning when the WoW client exposes appropriate data.
- Updated character overview, session gold tracking and configurable display and quest options.
- No automatic movement, combat, quest acceptance, buying or selling.

## Release artifact identity

- Package: `ForeverFlow_v0.5.6_CurseForge_Release.zip`
- SHA-256: `62abe9e8f49c54367405cbaffe3f67e72e596af3fa1bfd371d68a3e14ac2fa34`
- Manifest: `## Version: 0.5.6`, game interface `16001`
- Install root: `ForeverFlow/ForeverFlow.toc`
- Verified local ZIP integrity and 148 packaged files.

## GitHub → CurseForge publication

Existing `.github/workflows/package.yml` publishes the `release` branch or matching version tags to CurseForge project **1793262** using the configured repository secret. Do **not** push incomplete sources to `release`: it currently contains the older 0.5.5 release. The workflow must package the exact approved assets and source before enabling the public v0.5.6 release.
