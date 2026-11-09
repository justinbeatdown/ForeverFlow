# CurseForge release checklist — ForeverFlow 0.5.2 beta

## Current candidate
- Repository package: `dist/ForeverFlow_v0.5.2_Beta.zip`
- Target: World of Warcraft > Forever > 1.60.1 (addon interface 16001)
- Release channel: **Beta** until in-game acceptance testing is complete.
- Install root in ZIP: `ForeverFlow/ForeverFlow.toc` (exactly one ForeverFlow folder).
- Developer: ForeverFlow. Independent community addon; not affiliated with Blizzard.

## Upload to the already-created CurseForge project
1. Open your existing project dashboard and choose **Files > Upload File**.
2. Upload the verified `ForeverFlow_v0.5.2_Beta.zip` from `dist/`, or the ZIP artifact built by GitHub Actions.
3. Display name: `ForeverFlow 0.5.2 Beta — Branding & Live Guide Hotfix`.
4. Game version: **WoW Forever 1.60.1**, not Retail or Classic Era.
5. Release type: **Beta**. Do not select Release until a beta has been tested in the actual client.
6. Paste the changelog below and submit. CurseForge moderation determines when it becomes public.
7. For CurseForge App default sync, an approved **Release** file is ultimately required; beta alone is opt-in.

## User-facing changelog
**Version 0.5.2 — Branding and Live Guide hotfix**
- Uses the exact approved circular ForeverFlow logo across the minimap, Live Guide, and addon list.
- Improves Live Guide header spacing to keep the logo, title, and divider clear.
- Adjusts compact/expanded guide sizing to reduce clipped content.
- Retains smart recommended-quest auto-follow, native watch/focus attempts, and optional map guidance.
- No gameplay botting, automated movement, combat, gathering, buying, or selling.

**Beta notes:** Native quest focus and automatic waypoint behavior depend on the Forever client API and need further in-game validation.

## Acceptance before a full Release
- [ ] Install cleanly into `World of Warcraft/_forever_/Interface/AddOns`.
- [ ] Confirm official round logo appears uncropped on minimap, Live Guide, and AddOns list.
- [ ] Check compact, expanded, and collapsed Live Guide; no text/icon clipping.
- [ ] Complete and turn in a quest; verify the new recommended quest is auto-watched/focused where client APIs support it.
- [ ] Confirm a manually placed user waypoint isn't repeatedly overridden.
- [ ] Verify `/flow follow off` and `/flow follow on`.
- [ ] Test with `/console scriptErrors 1` and `/reload`; log any errors in Issues.
- [ ] Confirm GitHub Actions package validation passes.
- [ ] Confirm ZIP has a single root folder `ForeverFlow/`.

## Release description (short)
ForeverFlow helps WoW: Forever adventurers decide what to do next. Get smart quest suggestions, a compact Live Guide, optional automatic quest watching/focus when supported, session progress tracking, and profession-aware gold advice—all while playing manually.

## Release description (extended)
ForeverFlow is a polished, lightweight leveling and gold companion designed for World of Warcraft: Forever. It examines supported local quest, character, inventory, and profession data to recommend a useful next step. A movable and collapsible Live Guide keeps guidance visible without taking over the screen; the full dashboard offers detailed quest, gold, skills, character, and settings pages.

Features include recommended-quest auto-follow via supported native APIs, manual quest selection and skip actions, basic session tracking, and a gold-conscious leveling mode. ForeverFlow never automates combat or character movement. This beta does not claim complete turn-by-turn routing, live auction valuations, or universal compatibility with every other quest addon.

Support: https://github.com/justinbeatdown/ForeverFlow/issues
