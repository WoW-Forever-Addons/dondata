# DonData

The quest database of the Don addons for WoW Forever and WoW Classic Era, as an addon of its own.
Questdon and Leveldon need it, Geardon uses it when it is there; CurseForge installs it together with them.

What is in it: quests with their givers, turn-ins, chains and levels, objectives and the spawn points of objective mobs
and objects, quest texts, patrol routes of quest NPCs, dungeon levels and entrances, inns, auction houses, flight masters
and banks, ways around mountains.

- WoW Forever: `DonData_Camelot.toc` loads `Data/`.
- WoW Classic Era: `DonData_Vanilla.toc` loads `DataEra/`.

DonData has no window and no settings. It reads and learns the quest data for the addons that use it (what Questdon's
players learn, kept in `DonDataDB` and `DonDataCharDB`), knows the dungeons and gives one gear score per item for your
class and talent tree (stats, armor, weapon damage), used by Questdon and Geardon. Other addons read the tables from the
global `DonData` (`DonData.version` 3, `DonData.era`, `DonData.meta`, `DonData.tables`) and the rest through
`DonDataAPI` (version 4: quest data, dungeons since 2, gear score since 3, callbacks since 4), see `Engine/API.lua`.

Sources: All The Things (MIT), CMaNGOS classic-db (GPL v3), ForeverDB (GPL v3), recordings of Questdon's players and
checks in the game. Licenses per file: THIRD_PARTY_LICENSES.txt and the head of each data file.
