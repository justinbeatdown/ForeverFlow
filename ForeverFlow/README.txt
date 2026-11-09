ForeverFlow v0.5.5 | WoW: Forever (Interface 16001)

Install:
1. Exit the game completely.
2. Delete the prior Interface\AddOns\ForeverFlow folder.
3. Extract this ZIP so that Interface\AddOns\ForeverFlow\ForeverFlow.toc exists.
4. Log in. /flow opens the dashboard; the small Live Guide appears automatically.

Auto quest watch/focus is ON by default. When ForeverFlow recommends a NEW quest or its objective changes, it tries to add that quest to Blizzard's watch list and focuses its native quest waypoint. If native focus is unavailable, and there is no player custom map pin, it attempts an addon-owned map pin using client-provided coordinates. It will never invent location data. Manual quest/map focus changes are not reset at every six-second refresh.

Commands:
 /flow                  dashboard
 /flow guide            toggle Live Guide
 /flow hud tiny         compact ribbon
 /flow hud normal       expanded guide with buttons
 /flow follow on|off    automatic quest watch+focus
 /flow focus            retry quest watch+focus immediately
 /flow map              set a compatible map pin manually
 /flow next             try another quest
 /flow debug            status and last Lua error

Auto-focus does not automate movement, combat, looting, gathering or selling.
Nothing posts data outside of WoW.

Guide controls: left-click the small v/^ button to expand or compact the ribbon; right-click to collapse it to the title bar.

0.5.5 RC: /flow where (quest hint), /flow why (ranking factors), /flow status (diagnostics).
Quest-map coordinates are client-provided hints; not guaranteed objective locations.

0.5.5 commands: /flow stats, /flow pin, /flow unpin, /flow pace
Leveling pace is an estimate based on current session XP and appears after a reliable sample.

Discover Quests beta: Leveling > DISCOVER QUESTS or /flow discover shows eligible-looking
quest-line/map-start options reported by your current WoW: Forever client and
quest-giver options previously seen during gossip. These are hints, NOT confirmed
availability, optimized routing, or verified NPC pickup coordinates. Save, skip,
reset skips (/flow discoverreset), or open the general zone map. This feature
never automatically accepts quests, pins unverified NPCs or overrides auto-follow.
Forever-compatible external quest databases are not bundled due to licensing and
client-validation requirements. If the client exposes no quest lines/starts,
visit quest-givers or travel to other zones to discover more.

DISCOVER QUESTS (v0.5.5 Beta 4):
Open Leveling -> DISCOVER QUESTS, or type /flow discover. Offline recommendations
cover a curated set of 70 reported quest starts in The Barrens and Stonetalon.
BROWSE ZONES switches between local picks and the combined two-zone catalog.
PREV/NEXT moves through suggestions. SAVE/UNSAVE and SKIP persist. To revisit
skipped quests, type /flow discoverreset. MAP gives a reported pickup NPC and
coordinates; TomTom waypoints are supported when TomTom is installed.

These are candidate quests; prerequisites and actual NPC offers may differ
in Forever. "REPORTED PICKUP" does not mean currently obtainable. Other areas
retain the earlier client-observed discovery mode until their catalog expands.
Data provenance and quality limitations: DATA_SOURCES.txt.
