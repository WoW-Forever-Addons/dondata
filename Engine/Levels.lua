local _, ns = ...

---------------------------------------------------------------------------
-- (07.11.2026, Daniel: Questdon soll die Stufen sammeln) The level the game shows for every quest of our data,
-- asked from the server bit by bit. Forever's levels differ from the data (65 The Defias Brotherhood: ATT 14, the
-- server 18), and the minimum level can not be asked, the quest's level can (C_QuestLog.GetQuestDifficultyLevel after
-- C_QuestLog.RequestLoadQuestByID, also for quests that are not in the log).
--
--   * Forever only (Era ships CMaNGOS' levels). Starts START s after login, then one quest every GAP s (RATE a second),
--     never in combat, never while the manual /qd scan (Questdon Scan.lua) runs.
--   * Walks the quest IDs of ns.ATT_QUESTS in ascending order; the place is kept account-wide in
--     DonDataDB.levelScan = { p = last ID done, b = client build, v = data version, d = true when through }.
--     A new client build or new data starts it again from the first ID; nothing else is kept per quest.
--   * One request open at a time; no answer within WAIT s or "false": go on. Quests the account knows a level of
--     (DonDataDB.questLevels) are skipped without a request.
--   * A level is kept in DonDataDB.questLevels (as the quest log's levels, QuestData.lua ns.GameQuestLevel) only when
--     it differs from the shipped one (ns.GAME_LEVELS); the same level costs nothing. Export and sharing send it as
--     "Z <quest> <level>" (Export.lua), the data build takes it into GAME_LEVELS (store/extras.py, extra_quests.py).
--   * Any successful load of a quest of the data (other addons, Exists.lua) is read the same way.
---------------------------------------------------------------------------
local START = 60   -- seconds after login
local GAP = 0.5    -- seconds between two quests (2 a second)
local WAIT = 5     -- seconds to wait for the server's answer

local ids          -- sorted quest IDs (made when the walk starts, dropped when it is through)
local pos = 0      -- index into ids
local waiting, sentAt = nil, 0
local ticker
local stats = { asked = 0, found = 0, same = 0, none = 0 }

local function Now() return ns.Num(ns.Value(GetTime)) or 0 end

local function Build()
  if type(GetBuildInfo) ~= "function" then return "?" end
  local ok, _, build = pcall(GetBuildInfo)
  return ok and build ~= nil and ns.Usable(build) and tostring(build) or "?"
end
local function DataVersion()
  local meta = ns.ATT_META
  return type(meta) == "table" and type(meta.commit) == "string" and meta.commit:sub(1, 8) or "?"
end

local function State()
  local db = ns.db
  if not db then return nil end
  if type(db.levelScan) ~= "table" then db.levelScan = {} end
  local s = db.levelScan
  local b, v = Build(), DataVersion()
  if s.b ~= b or s.v ~= v then
    s.b, s.v, s.p, s.d = b, v, 0, nil
  end
  return s
end

local function Levels()
  local db = ns.db
  if not db then return nil end
  if type(db.questLevels) ~= "table" then db.questLevels = {} end
  return db.questLevels
end

-- Keep the server's level of a quest of the data: only one that differs from the shipped level.
-- Returns "new", "same" or nil (no level).
local function Note(id)
  local lv = ns.Num(ns.Value(C_QuestLog and C_QuestLog.GetQuestDifficultyLevel, id))
  if not lv or lv <= 0 or lv > 100 then return nil end
  lv = math.floor(lv)
  local store = Levels()
  if not store then return nil end
  local shipped = ns.GAME_LEVELS and ns.Num(ns.GAME_LEVELS[id])
  if shipped == lv then
    -- an older kept level of another build goes (the shipped one is right now); a kept equal one stays
    if store[id] ~= nil and store[id] ~= lv then store[id] = nil end
    return "same"
  end
  if store[id] ~= lv then store[id] = lv end
  return "new"
end
ns.NoteServerQuestLevel = Note

local function Stop()
  if ticker and ticker.Cancel then ticker:Cancel() end
  ticker, ids, waiting = nil, nil, nil
end

local function Count(result)
  if result == "new" then stats.found = stats.found + 1
  elseif result == "same" then stats.same = stats.same + 1
  else stats.none = stats.none + 1 end
end

local function Done(s, id)
  waiting = nil
  if id and id > (ns.Num(s.p) or 0) then s.p = id end
end

local function MakeIDs(s)
  ids = {}
  for id in pairs(ns.ATT_QUESTS or {}) do
    if type(id) == "number" and id > 0 then ids[#ids + 1] = id end
  end
  table.sort(ids)
  -- go on where the last session stopped
  local p = ns.Num(s.p) or 0
  pos = 0
  for i = 1, #ids do
    if ids[i] > p then break end
    pos = i
  end
end

local function Busy()
  if InCombatLockdown and InCombatLockdown() then return true end
  if UnitAffectingCombat and ns.True(ns.Value(UnitAffectingCombat, "player")) then return true end
  local scan = ns.db and ns.db.scan
  return type(scan) == "table" and scan.on == true -- the manual /qd scan asks fast already
end

local function Tick()
  local s = State()
  if not s or s.d then Stop() return end
  if waiting then
    if Now() - sentAt < WAIT and Now() >= sentAt then return end
    Count(Note(waiting)) -- no answer: whatever the client has
    Done(s, waiting)
  end
  if Busy() then return end
  if not ids then MakeIDs(s) end
  local store = Levels() or {}
  while true do
    pos = pos + 1
    local id = ids[pos]
    if not id then
      s.d = true
      Stop()
      return
    end
    if store[id] == nil then
      waiting, sentAt = id, Now()
      stats.asked = stats.asked + 1
      if not pcall(C_QuestLog.RequestLoadQuestByID, id) then
        Count(nil)
        Done(s, id)
      end
      return
    end
    Done(s, id)
  end
end

ns.On("QUEST_DATA_LOAD_RESULT", function(_, questID, success)
  local id = ns.Num(questID)
  if not id or not (ns.ATT_QUESTS and ns.ATT_QUESTS[id]) or ns.ERA then return end
  local ok = success == true and ns.Usable(success)
  if id == waiting then
    Count(ok and Note(id) or nil)
    local s = State()
    if s then Done(s, id) end
  elseif ok then
    Note(id)
  end
end)

local function CanRun()
  return not ns.ERA and C_QuestLog and type(C_QuestLog.RequestLoadQuestByID) == "function"
    and type(C_QuestLog.GetQuestDifficultyLevel) == "function"
end

function ns.StartLevelScan()
  local s = State()
  if ticker or not s or s.d or not CanRun() then return false end
  ticker = ns.NewTicker(GAP, Tick)
  return ticker ~= nil
end

ns.OnInit(function()
  if not CanRun() then return end
  ns.After(START, ns.StartLevelScan)
end)

-- For /qd diag: where the walk is.
function ns.LevelScanStatus()
  local s = ns.db and type(ns.db.levelScan) == "table" and ns.db.levelScan or {}
  local kept = 0
  for _ in pairs(ns.db and type(ns.db.questLevels) == "table" and ns.db.questLevels or {}) do kept = kept + 1 end
  return { at = ns.Num(s.p) or 0, done = s.d == true, running = ticker ~= nil, asked = stats.asked,
    found = stats.found, same = stats.same, none = stats.none, kept = kept, total = ids and #ids or nil }
end

-- (tests) one step now, the walk's state reset
function ns.LevelScanTick() Tick() end
function ns.LevelScanReset()
  Stop()
  pos, stats = 0, { asked = 0, found = 0, same = 0, none = 0 }
  if ns.db then ns.db.levelScan = nil end
end
