# Changes

## 1.2.4

- **Quest levels from the WoW Forever server:** levels for 3307 quests (before 589), so grey quests match the game. Questdon asks the server for quest levels in the background, two per second and never in combat.
- **Grey quests:** a quest counts as too low by the level the server gives it, the way the game greys it.
- **Empty "!":** a quest the quest giver does not offer at its level is hidden after one talk.
- **Learned from play:** another day of play added (spawns, walked ways, quest facts).
- WoW Forever build 70862.

## 1.2.3

- **Better ways on WoW Forever:** the arrow and the dotted line know far more of the ground players really walk (twice as many walked spots, many more cave insides). Small hills that only look like mountains on the map no longer cause long detours; places where players only tried to climb and slid back still count as mountain.
- **Quest data:** updated from the current All The Things files and ForeverDB 0.57.0 for WoW Forever (new prerequisites in Tirisfal Glades and Silverpine Forest, Arugal's Folly in five parts, more objective spots).
- **Learned from play:** a new day of play added: lowest levels quests are offered at, quest starts and turn-ins, quest items, objectives and NPC roles.

## 1.2.2

- **WoW Forever:** real quests are no longer hidden when the server does not answer a question about them.
- **WoW Forever:** quest titles the game does not have are asked for less often (no more requests every few seconds).
- **Quest data:** a new day of play on WoW Forever added: quests the server does not have, gathering spots, NPC roles, objectives and turn-ins.

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
