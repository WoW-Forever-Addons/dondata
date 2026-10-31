# DonData

The quest database of the Don addons for WoW Forever and WoW Classic Era, as an addon of its own.
Questdon needs it (and with Questdon, Leveldon); CurseForge installs it together with them.

What is in it: quests with their givers, turn-ins, chains and levels, objectives and the spawn points of objective mobs
and objects, quest texts, patrol routes of quest NPCs, dungeon levels and entrances, inns, auction houses, flight masters
and banks, ways around mountains.

- WoW Forever: `DonData_Camelot.toc` loads `Data/`.
- WoW Classic Era: `DonData_Vanilla.toc` loads `DataEra/`.

DonData does nothing by itself: no window, no settings, no saved variables. Other addons read the tables from the
global `DonData` (`DonData.version`, `DonData.era`, `DonData.meta`, `DonData.tables`).

Sources: All The Things (MIT), CMaNGOS classic-db (GPL v3), ForeverDB (GPL v3), recordings of Questdon's players and
checks in the game. Licenses per file: THIRD_PARTY_LICENSES.txt and the head of each data file.
