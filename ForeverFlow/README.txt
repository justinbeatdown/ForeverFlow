ForeverFlow v0.5.3 | WoW: Forever (Interface 16001)

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
