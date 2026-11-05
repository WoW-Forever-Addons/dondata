# Changes

## 1.2.1

- **WoW Forever build 70790:** the game tables are updated to the current client (quests unchanged).

## 1.2.0

- **Less to share:** a list of what the data already knows (Forever only) lets Questdon leave out of sharing and `/qd export` what everybody has anyway. Shared data is far smaller.
- **Quest data:** updated from the current All The Things files for WoW Forever.
- **Pin sizes:** new defaults 60 % on the world map and 85 % on the minimap (together with Questdon 1.5.0).
- **Addon list:** the addon has its own logo in the game's addon list.

## 1.1.0

- **First full release.** DonData is the quest database of the Don addons, for WoW Forever and WoW Classic Era in one download. **Questdon** and **Leveldon** need it; the CurseForge app installs it with them. If you install by hand, put the `DonData` folder next to them in `Interface\AddOns`. It has no window and nothing to set up.
- **Quest data:** quests with their givers, turn-ins, chains and levels, objectives and the spawn points of objective mobs and objects, quest texts, patrol routes of quest NPCs, dungeons with levels and entrances, inns, auction houses, flight masters and banks, ways around mountains.
- **Learning in one place:** what Questdon learns while you play (where quests really start and end, objective spots, NPC names) is now kept by DonData, so Leveldon uses it too, even without Questdon. It moves over from Questdon's saved data once by itself.
- **Dungeons:** names in your game language, levels and group finder ranges for Questdon, Leveldon and Geardon.
- **One gear score:** a value per item for your class and talent tree (stats, armor, weapon damage), so Questdon's reward advice and Geardon's upgrade arrow agree.
- **Light:** quest texts are only read when one is first needed (about 1 MB less memory after loading), learned NPC names are kept to 3000 per language.
- **More Forever quests:** quest IDs from the Forever game client fill gaps in the data; spawn fixes for Silverpine Forest, Winterspring and the Badlands.
- **For addon authors:** `DonDataAPI` version 4 (quest data, dungeons, gear score, callbacks "ready", "learned" and "gear").
