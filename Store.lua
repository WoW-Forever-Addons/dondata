local addonName, ns = ...
---------------------------------------------------------------------------
-- (30.10.2026, DONCORE_PLAN.md "DonData Lese-Engine" L2) What the Don addons learn about quests while playing is kept
-- here, in DonData's own saved variables, so Leveldon can use it without Questdon:
--   DonDataDB      account wide: the keys of LEARN_KEYS (before 30.10.2026 they were in QuestdonDB)
--   DonDataCharDB  per character: the keys of CHAR_KEYS (before: QuestdonCharDB, what quest givers offered)
-- Questdon's ns.db and ns.charDB are views (StoreView): a learned key reads and writes here, every other key (the
-- settings) in Questdon's own table. So the code keeps reading ns.db.learned, ns.db.notHere ... as before.
-- MoveLearned takes over what an older Questdon left in QuestdonDB once; it is then gone there (no copy kept twice).
---------------------------------------------------------------------------
ns.LEARN_KEYS = {
  learned = true, learnedObj = true, learnedCredit = true, learnedDrops = true, learnedItemStarts = true,
  npcSpots = true, notHere = true, questExists = true, questExistsBuild = true, npcNames = true, questLevels = true,
  objOrder = true, shared = true, movedOrderFix = true,
  levelScan = true, -- (07.11.2026) where the walk of Engine/Levels.lua is
  npcNamesOrder = true, -- (31.10.2026, C13) the order npcNames were first seen in, for its limit (QuestData.lua)
}
ns.CHAR_KEYS = { notOffered = true, offered = true, notOfferedInfo = true }
-- always there (the others are made by the code that needs them, as before)
local TABLES = { "learned", "learnedObj", "learnedCredit", "learnedDrops", "learnedItemStarts", "npcSpots", "notHere",
  "shared", "questExists" }

function ns.OpenStore()
  if type(DonDataDB) ~= "table" then DonDataDB = {} end
  if type(DonDataCharDB) ~= "table" then DonDataCharDB = {} end
  for _, k in ipairs(TABLES) do
    if type(DonDataDB[k]) ~= "table" then DonDataDB[k] = {} end
  end
  ns.ldb, ns.lcharDB = DonDataDB, DonDataCharDB
  return DonDataDB, DonDataCharDB
end

-- (31.10.2026, Kritikrunde) keys whose entries are tables of their own: merged one level deeper, so a thin entry the
-- store has already (npcNames.deDE with a few names, learned[id] with only start) does not drop the old one's rest
local DEEP = { npcNames = true, learned = true, learnedObj = true, learnedCredit = true }

-- fill what have lacks from v; depth 2: also inside entries both have
local function Fill(have, v, depth)
  for id, e in pairs(v) do
    local h = have[id]
    if h == nil then
      have[id] = e
    elseif depth > 1 and type(h) == "table" and type(e) == "table" then
      Fill(h, e, depth - 1)
    end
  end
end

-- what is in old (QuestdonDB or QuestdonCharDB) under keys moves into store; an entry the store has already wins
local function Move(old, store, keys)
  if type(old) ~= "table" or old == store then return 0 end
  local n = 0
  for k in pairs(keys) do
    local v = old[k]
    if v ~= nil then
      local have = store[k]
      if type(v) == "table" and type(have) == "table" and next(have) ~= nil then
        Fill(have, v, DEEP[k] and 2 or 1)
      elseif have == nil or (type(have) == "table" and next(have) == nil) then
        store[k] = v
      end
      old[k] = nil
      n = n + 1
    end
  end
  return n
end

function ns.MoveLearned(oldDB, oldChar)
  local db, char = ns.OpenStore()
  return Move(oldDB, db, ns.LEARN_KEYS) + Move(oldChar, char, ns.CHAR_KEYS)
end

-- a table that reads and writes keys of keys in store, all others in settings
function ns.StoreView(settings, store, keys)
  return setmetatable({}, {
    __index = function(_, k)
      if keys[k] then return store[k] end
      return settings[k]
    end,
    __newindex = function(_, k, v)
      if keys[k] then store[k] = v else settings[k] = v end
    end,
  })
end

if type(CreateFrame) == "function" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("ADDON_LOADED")
  f:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    ns.OpenStore()
  end)
end
