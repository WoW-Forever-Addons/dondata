# Changes

## 1.7.1

- **New Forever items judged right (Geardon, Questdon's reward glow):** the items added with WoW Forever now count their hit, critical strike, spell damage, healing, MP5, HP5, block value and spell penetration. Before, only their primary stats and armor counted, so a reward with hit or crit could show as clearly worse than what you wear.
- **New data:** quest data refreshed from players' recordings (quests, spawns, paths, services), and the items that start a quest with where they drop (new file, restart the game once).

## 1.7.0

- **Stat weights per spec for Geardon:** weights for every class and talent tree (levelling spec before the first talents), with hit, crit, spell hit, spell crit, spell power (also per school), healing, MP5, HP5, defense, dodge, parry, block, block value, weapon skill and spell penetration. Hit and crit count by what they add to your damage right now, and hit stops counting at the cap (8 % melee, 17 % spells from level 50), read like the game's character window, including school talents such as Shadow Focus.
- **Secondary stats of items in every language:** taken from the items' equip effects (new file, restart the game once).
- **Wrong quest point from the game:** when the game places a quest's objective in a zone where the quest has no giver, turn-in or objective at all, Questdon no longer uses that point for the arrow, the route or a map pin, and no longer learns it. Example: A Taste of Home, the game pointed to Silverpine Forest, the wine drops from the blood elves in Azshara. A spot learned there before is left out as well.

## 1.6.0

- **New data:** the quest data was refreshed twice. About 5,100 quests now, with the new Tip the Scales and Kum'isha's Endeavors quests and a lot of newly learned facts. Two quests that no longer exist are gone.
- **Riverglades services:** the inn and the flight masters of Rog'mar, Farholde Keep and Powderfuse Port show on the map with the right faction, and the symbols no longer land on the wrong continent map. Two flight points at Powderfuse Port that have no flight master in the game are gone.
- **Only the quests you can really do:** the profession specialisation quests (blacksmith, engineer, leatherworker) show only with the profession and only while you have not learned a specialisation of it. The 37 "The Alliance/Horde Needs ..." war effort quests are gone, because that event is not active.
- **Event quests only when they run:** an event quest shows only while the game lists it or the giver offered it this session, not because you saw it at the last event.
- **No false kill credit:** a mob that died long ago is no longer marked as the source of a quest objective, for example the spiders of From Seed to Sprout, where you plant seedlings.
- **Quest items used up later:** items a quest uses up are now linked to it, for example the three pieces of Lord Valthalak's Amulet to The Right Piece of Lord Valthalak's Amulet, so Questdon keeps them.
- **Quest colours in tooltips:** the level tag in NPC tooltips, the quest book, the tracker and the pin titles uses the same colour as the quest list.
- **Pictures and levels for pin cards:** the data now has level, model and rank of 1,850 mobs, so pin cards can show a small picture and the mob's level.
- **Smoother play:** learning from the game's quest points works in small steps instead of one long one, and the refresh after quest changes gives costly parts their own frames. Spawn points are kept instead of being rebuilt each time.

## 1.5.3

- **Explore quests point into the cave (The Jasperlode Mine, The Fargodeep Mine and nine more):** the objective is only the spot that counts, inside the mine, no longer spots outside; the Kobolds on the way are no longer marked as quest mobs.

## 1.5.2

- **Data from more players (21 November):** quest starts, turn-ins, objective places, quest levels, drops and paths from the recordings of two more players.
- **Hints of a New Plague? (Kinelory):** Kinelory stands right next to Quae, the walking was her escort quest. The hint and the map point now show her there.

## 1.5.1

- **Smoother play:** fixed short stutters. The background check of quest levels after an update asks only for changed quests, more slowly, and no longer makes the map and lists redraw; quest tags and levels from the log are read once per log change; armor and health changes of other units no longer wake the gear check.

## 1.5.0

- **Dungeon quests:** a list of dungeon and raid quests (from CMaNGOS) and the quest marks the game shows in your log, so the Don addons can mark Elite, Dungeon and Raid quests correctly.
- **Learned from play:** the days up to 21 November: more quest levels, objective places, spawns, services, paths and quest texts.

## 1.4.1

- **Learned from play:** the days up to 19 November, about 900 new facts: quest levels (now 1,820), objective places, gathering finds, services and paths.

## 1.4.0

- **Data of 18 November:** All The Things and ForeverDB brought more than 300 new quests (now over 5,000), among them 151 in Mount Hyjal, with their givers, turn-ins and texts, and new spawns and services.

## 1.3.1

- **Learned from play:** four more days of play (15 to 18 November), about 3650 new facts: quest starts, turn-ins, quest levels, objective places, gathering finds and paths.
- **Hints of a New Plague? (Kinelory):** the quest now shows where Kinelory walks in the Go'Shek Farm, with a hint to talk to her and take the escort quest.

## 1.3.0

- **New quest data:** 115 more quests (4698), among them the quests of Alcaz Prison and Blackmaw Hold and new quests in Shen'dralas, Desolace, Theramore and Tanaris, and the racial riding quests; more quest starts, turn-ins and objectives.
- **Learned from play:** three more days of play from over 590 players (where quests start and end, objective places, quest levels, gathering finds).
- **Two new dungeons:** Alcaz Prison (48 to 53) and Blackmaw Hold (55 to 60) with their level ranges.
- **Fewer wrong pins at the quest giver:** a learned objective spot right at the quest giver or the turn-in is left out when the quest's mobs or another place are known.
- **For Questdon 1.7.0:** usable items of each quest for the item buttons in the quest list, new defaults for new installs.

## 1.2.6

- **New quest data:** 231 more quests (4583), among them the quests of Krol'dok Stronghold and The Drowned City and many in Zephras Isle and the higher zones; more quest starts, turn-ins and objective places, fewer quests the game knows but the data did not.
- **Learned from play:** three more days of play (levels at which quests are offered, places of objectives, gathering finds, quest levels from the server).
- **No find places at the bank:** quest items taken out of the bank, mail, a trade or the auction house are not learned as a place where they are found.
- **Two new dungeons:** Krol'dok Stronghold (40 to 45) and The Drowned City (35 to 40) with their level ranges.
- For WoW Forever build 70888.

## 1.2.5

- **The arrow's ways around mountains and into caves are off by default:** the arrow points straight at the target.
- **Learned from play:** reports of single players are used when they match the quest data, and another day of play added (quest starts and turn-ins, walked ways, services).

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
