local _, ns = ...

---------------------------------------------------------------------------
-- (30.10.2026, DONCORE_PLAN.md "DonData Lese-Engine" L4) DonDataAPI: the reading part of QuestdonAPI, served by
-- DonData's engine, so a guide (Leveldon) can read the quest data without Questdon. Same names, same answers as
-- QuestdonAPI (Questdon's API.lua hands these functions on unchanged).
-- Versioned like QuestdonAPI: add functions, never change existing ones; bump VERSION when something is added.
--   1: GetQuest, QuestTitle, CanTakeQuest, CanTakeQuestLater, NotOfferedLevel, IsQuestDone, InQuestLog,
--      QuestNpcWalks, IsQuestComplete, CreatureName, QuestExists, QuestStart, BreadcrumbTargets, ObjectivePoints,
--      QuestPOI, ObjectiveHint, ItemName, TurnInPoint, DistanceTo, PlayerPosition, ObjectiveCreatures, TurnInNpc,
--      Ready (true once the engine started: with Questdon's settings or, without Questdon, at login)
-- The dungeon functions (QuestDungeon, DungeonLevelRange, Dungeons, DungeonsForLevel) and everything about the
-- arrow, the compass and Questdon's windows stay QuestdonAPI's. The arrow without Questdon: DonMapAPI.
---------------------------------------------------------------------------
local VERSION = 1

---------------------------------------------------------------------------
-- (moved from Questdon's Arrow.lua with the API) the state a quest's places depend on
---------------------------------------------------------------------------
-- (16.10. night, Daniel's /qd mem: "API ObjectivePoints" 156 KB and "arrow" 65 KB a second standing) the state a
-- quest's places depend on, as plain numbers in a table per quest (the signature was a new string of a dozen parts
-- at every look-up: the arrow 33 times a second, the list and the guide for every quest): complete, failed, from the
-- log; which objectives are done and how many each needs; the game's point; learned and shared places.
local function ObjState(questID)
  local mask, req, n = 0, 0, 0
  for i, o in ipairs(ns.ClientObjectives(questID)) do
    n = i
    if type(o) == "table" then
      if ns.True(o.finished) and i <= 30 then mask = mask + 2 ^ (i - 1) end
      req = req + (ns.Num(o.numRequired) or 0) * (i + 7)
    end
  end
  return mask, req, n
end
local function StampFill(questID, st)
  st.c, st.f, st.a = ns.IsQuestComplete(questID) and true or false, ns.IsQuestFailed(questID) and true or false,
    ns.IsAutoComplete(questID) and true or false
  st.mask, st.req, st.n = ObjState(questID)
  st.m, st.x, st.y = ns.QuestPOI(questID)
  st.lv = ns.LearnVersion and ns.LearnVersion() or 0
  st.pv = ns.SharedPlacesVersion and ns.SharedPlacesVersion(questID) or 0
  st.sv = ns.QuestSpotVersion and ns.QuestSpotVersion(questID) or 0
  return st
end
local function StampSame(questID, st)
  if type(st) ~= "table" then return false end
  if st.c ~= (ns.IsQuestComplete(questID) and true or false) or st.f ~= (ns.IsQuestFailed(questID) and true or false)
      or st.a ~= (ns.IsAutoComplete(questID) and true or false) then return false end
  local mask, req, n = ObjState(questID)
  if st.mask ~= mask or st.req ~= req or st.n ~= n then return false end
  local m, x, y = ns.QuestPOI(questID)
  if st.m ~= m or st.x ~= x or st.y ~= y then return false end
  return st.lv == (ns.LearnVersion and ns.LearnVersion() or 0)
    and st.pv == (ns.SharedPlacesVersion and ns.SharedPlacesVersion(questID) or 0)
    and st.sv == (ns.QuestSpotVersion and ns.QuestSpotVersion(questID) or 0)
end
ns.QuestStampFill, ns.QuestStampSame = StampFill, StampSame -- (the API keeps its places by the same state)
-- (23.10., /qd mem) which part of the state changed, for the "... new: <why>" counts (only while /qd mem runs)
local function StampWhy(questID, st)
  if type(st) ~= "table" then return "first" end
  if st.c ~= (ns.IsQuestComplete(questID) and true or false) or st.f ~= (ns.IsQuestFailed(questID) and true or false)
      or st.a ~= (ns.IsAutoComplete(questID) and true or false) then return "complete" end
  local mask, req, n = ObjState(questID)
  if st.mask ~= mask or st.req ~= req or st.n ~= n then return "objectives" end
  local m, x, y = ns.QuestPOI(questID)
  if st.m ~= m or st.x ~= x or st.y ~= y then return "game point" end
  if st.lv ~= (ns.LearnVersion and ns.LearnVersion() or 0) then return "learned" end
  if st.pv ~= (ns.SharedPlacesVersion and ns.SharedPlacesVersion(questID) or 0) then return "shared" end
  if st.sv ~= (ns.QuestSpotVersion and ns.QuestSpotVersion(questID) or 0) then return "spots" end
  return "time"
end
function ns.QuestStampWhy(questID, st, label)
  if ns.MemProfiling and ns.MemProfiling() then ns.MemCount(label .. ": " .. StampWhy(questID, st)) end
end

local Q = ns.ATT_QUESTS or {}

local function Copy(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do c[k] = v end
  return c
end

local API = { version = VERSION }

-- Static data: { questID, mapID, x, y (0-100), faction "A"/"H"/nil, minLevel, prereqs, givers, flags, name,
-- origin } origin (1.13): nil = ATT's current Forever data, "o" = only in ATT's older classic data
-- (zzOLD, may be gone in Forever), "of" = zzOLD but marked by ATT as added in Forever.
-- dungeon (1.18): ATT instance ID of the dungeon the quest belongs to, else nil (see QuestDungeon).
-- (23.10., Daniel's /qd mem with Leveldon: "API GetQuest" 3 KB a second at 2.5 calls) the data does not change: one
-- answer table per quest, kept (callers only read it)
local questAnswers = {}
function API.GetQuest(questID)
  local q = Q[questID]
  if not q then return nil end
  local kept = questAnswers[questID]
  if kept and kept.q == q then return kept.out end
  local out = {
    questID = questID, mapID = q[1], x = q[2], y = q[3], faction = q[4], minLevel = q[5],
    prereqs = Copy(q[6]), givers = Copy(q[7]), flags = q[8] or "", name = q[13], origin = q[14],
    dungeon = q[15],
    classes = Copy(q[9]), -- (1.3.6) class IDs of a class quest (1 warrior ... 11 druid), else nil
  }
  questAnswers[questID] = { q = q, out = out }
  return out
end

function API.QuestTitle(questID) return ns.QuestTitle(questID) end
-- CanTakeQuest: can this character pick the quest up right now, by best
-- knowledge. Data rules (level, faction, race, class, prerequisites), false for
-- quests the server does not know (1.13), and (1.24) false when this
-- character's quest giver did not offer it at the current level (until the
-- level rises) or when the client's quest lines say it is not available yet.
function API.CanTakeQuest(questID) return ns.CanTakeQuest(questID) end
-- (API 2, Leveldon 09.10.) CanTakeQuestLater: could this character take the quest once its level is high
-- enough? false when something else blocks it: a prerequisite not done, faction, race, class, profession,
-- a quest the server does not know. A guide skips such a quest instead of waiting for it.
function API.CanTakeQuestLater(questID)
  if ns.IsQuestDone(questID) or ns.InQuestLog(questID) then return false end
  return ns.CanTakeQuest(questID, nil, 100) and true or false
end
-- (1.3.6, Leveldon) the level at which this character's quest giver did not offer the quest (Questdon read
-- the NPC's dialog), while that holds (until a level up), else nil
function API.NotOfferedLevel(questID) return ns.NotOfferedLevel and ns.NotOfferedLevel(questID) or nil end
function API.IsQuestDone(questID) return ns.IsQuestDone(questID) end
function API.InQuestLog(questID) return ns.InQuestLog(questID) end
-- (1.3.6) the quest giver (turnin false) or turn-in NPC walks around (seen at places far apart, or known)
function API.QuestNpcWalks(questID, turnin) return ns.QuestNpcWalks and ns.QuestNpcWalks(questID, turnin) or false end
function API.IsQuestComplete(questID) return ns.IsQuestComplete(questID) end
function API.CreatureName(creatureID) return ns.CreatureName(creatureID) end

-- Does the quest exist on this server? (1.13)
-- true: in the log or confirmed by the server this session; false: the server
-- said it does not know the quest (CanTakeQuest is then false too); nil:
-- unknown, the server is asked (answer within seconds, QUEST_DATA_LOAD_RESULT).
function API.QuestExists(questID) return ns.QuestExists(questID) end

-- Where to pick the quest up: mapID, x, y (0-1), npcName
function API.QuestStart(questID)
  local m, x, y, npc = ns.QuestStart(questID)
  if not m or not x then return nil end
  return m, x / 100, y / 100, npc
end

-- (24.10.) The quests a breadcrumb quest leads to: { questID, ... }, empty for a quest that is no breadcrumb
function API.BreadcrumbTargets(questID)
  return ns.BreadcrumbTargets and ns.BreadcrumbTargets(questID) or {}
end

-- Points (0-1) for unfinished objectives of a quest in the log: { {mapID, x, y}, ... }
-- 1.14: a point may carry needsItem = itemID: the objective needs that item used
-- somewhere else, and this is where to get it. The place of use is not among the
-- points until the item is in the bags.
-- 1.15: Blizzard's own objective point (see QuestPOI) comes first, with
-- source = "blizzard"; the other points have no source field.
-- 1.16: optional index = objective index (client order, as in
-- C_QuestLog.GetQuestObjectives) the point belongs to. The Blizzard point
-- carries it only when exactly one objective is still open.
-- (16.10. late, Daniel's /qd mem) Leveldon asks for a quest's places several times a second (its window, the
-- nearest spot, the route fitting): the list is kept while the quest's state is the same (the arrow's signature:
-- complete, objectives done, the game's point, learned and shared places), until the bags change (an item to use,
-- an item to get), the zone changes or 30 seconds passed. The same table is returned: callers only read it.
local apiPts = {} -- [questID] = { sig =, at =, list =, bags = } (bags: its places depend on the bags)
for _, e in ipairs({ "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD" }) do
  ns.On(e, function() apiPts = {} end)
end
-- (16.10. late) looting gives a bag update every few seconds: only the quests whose places depend on the bags
ns.On("BAG_UPDATE_DELAYED", function()
  for q, c in pairs(apiPts) do if c.bags then apiPts[q] = nil end end
end)
local lastBags
local apiSeen = {} -- (23.10., /qd mem) quests whose places were asked for before (to tell a forgotten entry from a first one)
function ns.ForgetApiPoints() apiPts = {} end -- (tests)
local BuildObjectivePoints
function API.ObjectivePoints(questID)
  questID = ns.Num(questID)
  if not questID or not ns.QuestStampSame then return BuildObjectivePoints(questID) end
  local now = ns.Num(ns.Value(GetTime)) or 0
  local c = apiPts[questID]
  if c and now - c.at <= 30 and now >= c.at and ns.QuestStampSame(questID, c.st) then return c.list end
  -- (23.10.) while /qd mem runs: why the places were worked out again ("first" also after a bag or zone change)
  if c and ns.QuestStampWhy then ns.QuestStampWhy(questID, c.st, "API points new")
  elseif ns.MemProfiling and ns.MemProfiling() then ns.MemCount(apiSeen[questID] and "API points new: bags or zone" or "API points new: first") end
  apiSeen[questID] = true
  local list = BuildObjectivePoints(questID)
  apiPts[questID] = { st = ns.QuestStampFill(questID, {}), at = now, list = list, bags = lastBags or #list == 0 }
  return list
end
function BuildObjectivePoints(questID)
  local list = {}
  local m, x, y, kind, source = ns.QuestPOI(questID)
  if m and kind == "objective" then
    local openIndex = ns.ObjectiveState and select(3, ns.ObjectiveState(questID)) or nil
    list[1] = { mapID = m, x = x, y = y, source = source, index = openIndex }
  end
  lastBags = false
  -- (23.10.) the points of AllObjectivePoints are new tables of this call: handed on as they are (they were copied
  -- into a second set of tables)
  for _, p in ipairs(ns.AllObjectivePoints(questID)) do
    if p.needsItem or p.useSpot then lastBags = true end
    list[#list + 1] = p
  end
  return list
end

-- (1.15) Blizzard's own point for a quest in the log (the client's quest POI
-- or next waypoint): mapID, x, y (0-1), kind ("objective" or "turnin"),
-- source ("blizzard"). nil when the client has none, the quest failed, or the
-- point is where an item must be used that the player does not have yet.
function API.QuestPOI(questID)
  local m, x, y, kind, source = ns.QuestPOI(questID)
  if not m then return nil end
  return m, x, y, kind, source
end

-- (1.14) itemID when an open objective needs an item the player does not have
-- yet (to use at a place), else nil. Second value: true if ObjectivePoints has
-- a place to get it; false: nothing known, say "first get <item>" instead.
function API.ObjectiveHint(questID)
  return ns.ObjectiveHint(questID)
end

-- (1.14) Item name for texts (falls back to "the quest item", localized).
function API.ItemName(itemID) return ns.ItemName(itemID) end

-- Best guess where to turn the quest in: mapID, x, y (0-1), source
-- ("blizzard", "learned", "data" = known turn-in NPC, "followup" = giver of the next quest, "giver" = same NPC;
-- 1.15: never "giver" for quests started by an item)
function API.TurnInPoint(questID)
  return ns.TurnInPoint(questID, true)
end

-- Distance in yards from the player (nil if another continent / no position)
-- (16.10.) one target table for all calls (the arrow's world position cache compares its fields, not only the table)
local distTarget = {}
function API.DistanceTo(mapID, x, y)
  if not ns.DistanceAndBearing then return nil end
  distTarget.mapID, distTarget.x, distTarget.y = mapID, x, y
  return ns.DistanceAndBearing(distTarget)
end

-- (23.10., Leveldon's /lvd mem) the player's map and position (0-1) as Questdon reads it: from UnitPosition where it
-- fits the map, so no new vector table as with C_Map.GetPlayerMapPosition. nil without a position.
function API.PlayerPosition()
  if not ns.PlayerPosition then return nil end
  return ns.PlayerPosition()
end
-- (1.3.6) The mobs of a quest's objectives: { [index] = { ids = { creatureID, ... }, need = n or nil, done } }
-- (data creatures; need and done from the game for a quest in the log)
-- (17.10.) kept until the next quest log event (the same table: callers only read it)
local apiCreatures, apiCreaturesGen = {}, {}
local BuildObjectiveCreatures
function API.ObjectiveCreatures(questID)
  local gen = ns.LogGen and ns.LogGen()
  if gen and type(questID) == "number" then
    if apiCreaturesGen[questID] == gen and apiCreatures[questID] then return apiCreatures[questID] end
    local out = BuildObjectiveCreatures(questID)
    apiCreatures[questID], apiCreaturesGen[questID] = out, gen
    return out
  end
  return BuildObjectiveCreatures(questID)
end
function BuildObjectiveCreatures(questID)
  local out = {}
  local objs = ns.ATT_OBJECTIVES and ns.ATT_OBJECTIVES[questID]
  local client = ns.InQuestLog(questID) and ns.ClientObjectives(questID) or {}
  if type(objs) ~= "table" then return out end
  for idx, o in pairs(objs) do
    if type(idx) == "number" and type(o) == "table" and type(o[1]) == "table" and #o[1] > 0 then
      local c = client[idx]
      out[idx] = { ids = Copy(o[1]), need = type(c) == "table" and ns.Num(c.numRequired) or nil,
        done = type(c) == "table" and ns.True(c.finished) or false }
    end
  end
  return out
end
-- (1.3.6) Who takes a quest: creature ID (nil if unknown) and name (game language where known)
function API.TurnInNpc(questID)
  local e = ns.QUEST_ENDS and ns.QUEST_ENDS[questID]
  local id = e and ns.Num(e[4]) or nil
  local name = id and ns.LocalNpcName and ns.LocalNpcName(id) or nil
  local learned = ns.db and ns.db.learned and ns.db.learned[questID]
  return id, name or (learned and learned.finish and learned.finish.npc) or nil
end
function API.Ready() return ns.Started and ns.Started() or false end

-- every API function in a scope of its own (Core.lua ns.ScopeCall)
for k, f in pairs(API) do
  if type(f) == "function" then API[k] = function(...) return ns.ScopeCall(f, ...) end end
end

DonDataAPI = API
ns.DonDataAPI = API
