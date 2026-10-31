local addonName, ns = ...
---------------------------------------------------------------------------
-- (30.10.2026, DONCORE_PLAN.md "DonData") DonData: the quest data of the Don addons as an addon of its own.
-- The files of Data\ (WoW Forever, DonData_Camelot.toc) or DataEra\ (Classic Era, DonData_Vanilla.toc) fill this
-- addon's ns, as they filled Questdon's before; this file comes last and hands the tables on in the global DonData.
-- Addons that need the data set "## Dependencies: DonData" and read DonData.tables (Questdon: DataLink.lua).
--   DonData.version  format of what is handed on; only ever added to, never changed (like QuestdonAPI)
--   DonData.era      true when the Classic Era data loaded
--   DonData.meta     ns.ATT_META (source commit, counts)
--   DonData.tables   the tables by name (ATT_QUESTS, ATT_OBJECTIVES, QUEST_TEXTS, SPAWNS, WALKS, ...): read only;
--                    Questdon fills learned places into some of them while playing, as before
--   DonData.ns       (2) this addon's whole namespace (the same table as tables): Questdon's Link.lua makes its own ns
--                    a shell on it, so both addons share one namespace (DONCORE_PLAN.md "DonData Lese-Engine")
--   1: the first set
--   2: DonData.ns
--   3: (31.10.2026) the dungeons' data part in the engine (Engine/Dungeons.lua: QuestDungeon, DungeonName, the level
--      range); Questdon's Dungeons.lua reads it from there
---------------------------------------------------------------------------
local VERSION = 3
local meta = ns.ATT_META or {}
DonData = { version = VERSION, era = meta.era == true, meta = meta, tables = ns, ns = ns }
