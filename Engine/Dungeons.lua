local _, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- (31.10.2026, DONCORE_PLAN.md "DonData Lese-Engine") The data part of Questdon's Dungeons.lua, moved into the
-- engine so the guide (Leveldon) and Geardon get a dungeon's name and level range without Questdon (DonDataAPI 2):
-- the dungeon of a quest, the client's name of a dungeon, its level range (the game's Group Finder first, then
-- DonData's Data/Dungeon_Levels.lua). Entrances, pins, the dungeon list and /qd dungeons stay in Questdon's
-- Dungeons.lua (one namespace, Questdon/Link.lua: it reads these functions from here).
-- ns.ATT_DUNGEONS: [instanceID] = { name (English), uiMapID, entranceMap, x, y, minLevel }
---------------------------------------------------------------------------
local Q = ns.ATT_QUESTS or {}
local D = ns.ATT_DUNGEONS or {}
local DUNGEON, NAME_EN = 15, 1
local UIMAP, MINLEVEL = 2, 6

-- Dungeon of a quest: instanceID or nil.
function ns.QuestDungeon(questID)
  local q = Q[questID]
  return q and q[DUNGEON] or nil
end

-- Localised name: the client's name of the dungeon map, else ATT's English name.
function ns.DungeonName(inst)
  local d = D[inst]
  if not d then return inst and L["Dungeon %d"]:format(tonumber(inst) or 0) or "?" end
  if d[UIMAP] and C_Map then
    local info = ns.Value(C_Map.GetMapInfo, d[UIMAP])
    local name = type(info) == "table" and info.name
    if type(name) == "string" and ns.Usable(name) and name ~= "" then return name end
  end
  return d[NAME_EN] or L["Dungeon %d"]:format(tonumber(inst) or 0)
end

---------------------------------------------------------------------------
-- (1.3.5, Daniel 10.10.) Level range of a dungeon. The sources disagree (Data/Dungeon_Levels.lua names
-- them), so the game's own values come first: the Group Finder knows a suggested level range per
-- activity (C_LFGList.GetActivityInfoTable: minLevelSuggestion / maxLevelSuggestion, else minLevel).
-- An activity belongs to a dungeon by its instance map (the classic map IDs below), else by its name
-- (the client's dungeon name; wings such as "Scarlet Monastery - Library" count for the whole dungeon:
-- lowest minimum, highest maximum). Read once per session; while the client gives nothing, again at
-- most once a minute. Unknown, missing or secret values are left out.
---------------------------------------------------------------------------
local LEVELS = ns.DUNGEON_LEVELS or {}
local GAME_MAP = { [63] = 36, [64] = 33, [226] = 389, [227] = 48, [228] = 230, [229] = 229, [230] = 429, [231] = 90,
  [232] = 349, [233] = 129, [234] = 47, [236] = 329, [237] = 109, [238] = 34, [239] = 70, [240] = 43, [241] = 209, [316] = 189 }
ns.DUNGEON_GAME_MAP = GAME_MAP -- (31.10.2026) Questdon's Dungeons.lua (the journal's icons) reads it
local DUNGEON_CATEGORY = 2
local RESCAN = 60
local game, gameAt
local gameStats = { activities = 0, matched = 0, scans = 0 }
function ns.DungeonGameLevelStats() return gameStats end

local function Now() return ns.Num(ns.Value(GetTime)) or 0 end
local function Str(v) return type(v) == "string" and ns.Usable(v) and v ~= "" and v or nil end

-- The dungeon an activity name belongs to: the longest dungeon name it starts with.
local function ByName(name, names)
  local best, bestLen
  local low = name:lower()
  local short = low:gsub("^the%s+", "")
  for inst, list in pairs(names) do
    for _, n in ipairs(list) do
      if (low:sub(1, #n) == n or short:sub(1, #n) == n) and (not bestLen or #n > bestLen) then best, bestLen = inst, #n end
    end
  end
  return best
end

local function ScanGame()
  local now = Now()
  if game and (next(game) or now - (gameAt or 0) < RESCAN) then return game end
  game, gameAt = {}, now
  local lfg = C_LFGList
  if type(lfg) ~= "table" or type(lfg.GetAvailableActivities) ~= "function" or type(lfg.GetActivityInfoTable) ~= "function" then return game end
  gameStats.scans = gameStats.scans + 1
  local byMap = {}
  for inst, m in pairs(GAME_MAP) do byMap[m] = inst end
  local names = {}
  for inst, d in pairs(D) do
    local list = {}
    for _, n in ipairs({ Str(ns.DungeonName(inst)), Str(d[NAME_EN]) }) do
      local low = n:lower()
      list[#list + 1] = low
      local short = low:gsub("^the%s+", "")
      if short ~= low then list[#list + 1] = short end
    end
    names[inst] = list
  end
  local cats, seenCat = {}, {}
  if type(lfg.GetAvailableCategories) == "function" then
    local ok, list = pcall(lfg.GetAvailableCategories)
    if ok and type(list) == "table" then
      for _, c in ipairs(list) do c = ns.Num(c) if c and not seenCat[c] then seenCat[c] = true cats[#cats + 1] = c end end
    end
  end
  if not seenCat[DUNGEON_CATEGORY] then cats[#cats + 1] = DUNGEON_CATEGORY end
  for _, cat in ipairs(cats) do
    local ok, acts = pcall(lfg.GetAvailableActivities, cat)
    for _, act in ipairs(ok and type(acts) == "table" and acts or {}) do
      local okI, info = pcall(lfg.GetActivityInfoTable, act)
      if okI and type(info) == "table" then
        gameStats.activities = gameStats.activities + 1
        local inst = byMap[ns.Num(info.mapID) or -1]
        local name = Str(info.fullName) or Str(info.shortName)
        if not inst and name then inst = ByName(name, names) end
        local lo = ns.Num(info.minLevelSuggestion)
        if not lo or lo <= 0 then lo = ns.Num(info.minLevel) end
        local hi = ns.Num(info.maxLevelSuggestion)
        if inst and lo and lo > 0 then
          gameStats.matched = gameStats.matched + 1
          local g = game[inst]
          if not g then g = {} game[inst] = g end
          if not g.min or lo < g.min then g.min = lo end
          if hi and hi >= lo and (not g.max or hi > g.max) then g.max = hi end
        end
      end
    end
  end
  return game
end
-- (tests) start over with the next question
function ns.ResetDungeonGameLevels() game, gameAt = nil, nil end

-- Level range of a dungeon: min, max, source ("game" or "data"); nil if none is known.
-- The game's minimum wins; its maximum where it has one, else the table's (when it fits), else the minimum.
function ns.DungeonLevelRange(inst)
  local t = LEVELS[inst]
  local g = inst and ScanGame()[inst]
  if g and g.min then
    local max = g.max or (t and t[2] >= g.min and t[2]) or g.min
    return g.min, max, "game"
  end
  if t then return t[1], t[2], "data" end
  local d = D[inst]
  if d and d[MINLEVEL] then return d[MINLEVEL], d[MINLEVEL], "data" end
  return nil
end
-- Data table only (for /qd dungeonlevels): min, max or nil.
function ns.DungeonTableRange(inst)
  local t = LEVELS[inst]
  if t then return t[1], t[2] end
end
function ns.DungeonGameRange(inst)
  local g = inst and ScanGame()[inst]
  if g and g.min then return g.min, g.max end
end

-- (1.3.5) the minimum of the range (was ATT's minimum level)
function ns.DungeonMinLevel(inst)
  return (ns.DungeonLevelRange(inst))
end

-- Where the player stands against a range: "fits" (inside), "later" (below its minimum: second value
-- = levels to go), "below" (above its maximum), nil without a range or level.
function ns.DungeonFit(inst, level)
  level = level or ns.PlayerLevel()
  local lo, hi = ns.DungeonLevelRange(inst)
  if not (lo and level) then return nil end
  if level < lo then return "later", lo - level end
  if hi and level > hi then return "below" end
  return "fits"
end
