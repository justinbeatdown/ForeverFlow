# ForeverFlow v0.5.6 World Coverage

Offline database: 4,346 documented quest starts across 47 distinct map areas, imported (modified) from EverythingQuests' Forever quest data under MIT licensing. It does not claim all server-specific quests, all maps or all dungeon/raid quests are present. Client-based discovery is used where available.

Eligibility filters: min level, quest difficulty, races, classes, prerequisite any/all, mutual exclusions, in-log and completed quests, parent gate, chain replacement, repeatable exclusion. Quests requiring reputation and profession gates are omitted conservatively. Starting item availability cannot be guaranteed.

Performance: the current implementation scans the offline quest table on demand and caps displayed candidates; future versions should build zone indexes and cache candidate scans across refreshes.

Known limits: no verified every-zone coverage, no complete NPC name index, no automated route distance graph or flight-point knowledge, no full cross-zone objective location data.

NOT FINAL: validate in game and on characters across both factions and multiple levels before publishing.

Profession coach supports all professions the client reports. Steps are skill/rank aware but not a verified 1-to-300 recipe-by-recipe guide; trainer ranks, material economy and server-custom recipes still require validation.
