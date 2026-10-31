local _, ns = ...

---------------------------------------------------------------------------
-- (31.10.2026, Daniel: "a common database under DonData" for judging gear; offen/sonstiges.md "Gemeinsame
-- Ausrüstungsbewertung") One value of an item for the player's class and talent tree, so Geardon's arrow and Questdon's
-- reward glow judge alike (DonDataAPI 3: GearValue, GearCompare, GearWeights).
--
-- Daniel's choices 31.10.2026: stats, armor and weapon DPS in one number; wands by DPS first (stats only when the DPS
-- differs by less than 5 %); ranged weapons of classes other than hunters by their stats (DPS only breaks a tie);
-- the item level only as the last tie-break.
--
-- Sources (checked 31.10.2026, DATENQUELLEN.md):
--   Stat weights: the common ground of levelling and Forever guides (store/analysis/stat_weights.py, 13.10.2026), the
--     same numbers Questdon's Rewards.lua and Geardon's Upgrade.lua carry.
--   Warcraft Tavern, WoW Forever "Stats & Attributes Guide" (warcrafttavern.com/forever/guides/stats/): 14 attack power
--     = 1 weapon DPS; 2 attack power per Strength for warriors, paladins, shamans and druids, 1 for the others; 2 ranged
--     attack power per Agility for hunters; 10 health per Stamina; 2 armor per Agility.
--   warcraft.wiki.gg "Attack power": weapon damage = (weapon DPS + AP / 14) x speed (before 6.0.2).
--   warcraft.wiki.gg "Armor" / "Damage reduction": reduction = A / (A + 400 + 85 L) against attackers of level L up to
--     59, A / (A + 400 + 85 (L + 4.5 (L - 59))) from 60.
--
-- The value, in points of the class's stat weights:
--   stats   Strength, Agility, Stamina, Intellect, Spirit times the weights
--   AP      attack power on the item: one point of AP is worth the Strength weight / AP per Strength (hunters: the
--           Agility weight / 2, their AP is ranged AP); a class whose Strength weight is 0 gets nothing from melee AP
--   DPS     a melee weapon: 14 x the value of one AP (so casters and hunters, Strength weight 0, judge it by stats as
--           before); a hunter's bow, gun or crossbow: 14 x the value of one ranged AP; other ranged weapons and wands
--           count no DPS in the value (wands: see GearCompare)
--   armor   valued as the Stamina it would equal in effective health against a mob of your level: one point of armor
--           raises effective health by H / K, one Stamina by 10 (A + K) / K, so one armor = H / (10 (A + K)) Stamina
--           (H your health, A your armor, K = 400 + 85 L); times the Stamina weight
---------------------------------------------------------------------------

-- strength, agility, stamina, intellect, spirit by class ID (1 warrior ... 11 druid)
local WEIGHTS = {
  [1] = { 2, 1.5, 1.25, 0, 0.5 }, [2] = { 2, 1.25, 0.5, 0.75, 0.5 }, [3] = { 0, 2, 0.5, 1, 1.25 },
  [4] = { 1.5, 2, 0.75, 0, 0.75 }, [5] = { 0, 0, 1, 1.75, 1.5 }, [7] = { 2, 1.5, 0.5, 1, 0.25 },
  [8] = { 0, 0, 1, 2, 1.5 }, [9] = { 0, 0, 1.5, 1.75, 1.25 }, [11] = { 1.75, 1.75, 0.75, 0.25, 0.5 },
}
-- shamans and druids with most talent points in a caster tree (Elemental, Balance, Restoration)
local CASTER_TREES = { [7] = { [1] = true, [3] = true }, [11] = { [1] = true, [3] = true } }
local CASTER_WEIGHTS = { 0, 0, 0.5, 1.75, 1.25 }
local AP_PER_STR = { [1] = 2, [2] = 2, [7] = 2, [11] = 2 } -- others 1
local HUNTER, WAND_DPS_SHARE = 3, 0.05
ns.GEAR_WEIGHTS, ns.GEAR_CASTER_WEIGHTS = WEIGHTS, CASTER_WEIGHTS -- (tests: equal to Questdon's and Geardon's)

local STAT_KEYS = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STAMINA_SHORT",
  "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_SPIRIT_SHORT" }
local WEAPON, WAND = 2, 19
local RANGED_SUB = { [2] = true, [3] = true, [16] = true, [18] = true } -- bow, gun, thrown, crossbow

local function ClassID()
  local ok, _, _, id = pcall(UnitClass, "player")
  return ok and ns.Num(id) or nil
end
local function Tree()
  local fn = rawget(_G, "GetTalentTabInfo")
  if type(fn) ~= "function" then return 0 end
  local best, bestN = 0, 0
  for i = 1, 3 do
    local ok, _, _, a, _, b = pcall(fn, i)
    local n = ok and (ns.Num(a) or ns.Num(b)) or nil
    if n and n > bestN then best, bestN = i, n end
  end
  return best
end

-- The weights for a class and tree (default: the player's), and the class ID.
-- (Kritikrunde) the player's are kept until level, talents, health, armor or gear change (Geardon asks for every bag item)
local mine = {}
local function Forget() mine.w, mine.class, mine.armorSta = nil, nil, nil end
if ns.On then
  for _, e in ipairs({ "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_EQUIPMENT_CHANGED",
      "UNIT_MAXHEALTH", "UNIT_RESISTANCES", "PLAYER_ENTERING_WORLD" }) do
    ns.On(e, function(_, unit) if unit == nil or unit == "player" then Forget() end end)
  end
end
function ns.GearWeights(class, tree)
  if class == nil and tree == nil and mine.w then return mine.w, mine.class end
  local c = class or ClassID()
  if not c then return nil end
  local t = tree or (CASTER_TREES[c] and Tree()) or 0
  local w = (CASTER_TREES[c] and CASTER_TREES[c][t]) and CASTER_WEIGHTS or WEIGHTS[c]
  -- events reach the engine only after login: a shaman's or druid's tree is kept only once the game names one
  if class == nil and tree == nil and (t ~= 0 or not CASTER_TREES[c]) then mine.w, mine.class = w, c end
  return w, c
end

---------------------------------------------------------------------------
-- What an item carries, read once per link (item stats do not change): a flat table of numbers, kept up to 400 links.
---------------------------------------------------------------------------
local cache, cacheN = {}, 0
local ARMOR_PAT, DPS_PAT
local function Pattern(t) return "^" .. t:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0"):gsub("%%[sd]", "([%%d%%.,]+)") .. "$" end
local function TipNumbers(link)
  local tip = C_TooltipInfo and C_TooltipInfo.GetHyperlink
  if type(tip) ~= "function" then return nil, nil end
  ARMOR_PAT = ARMOR_PAT or Pattern(type(ARMOR_TEMPLATE) == "string" and ARMOR_TEMPLATE or "%s Armor")
  DPS_PAT = DPS_PAT or Pattern(type(DPS_TEMPLATE) == "string" and DPS_TEMPLATE or "(%s damage per second)")
  local ok, data = pcall(tip, link)
  local armor, dps
  for _, line in ipairs(ok and type(data) == "table" and type(data.lines) == "table" and data.lines or {}) do
    local txt = type(line) == "table" and line.leftText
    if type(txt) == "string" then
      local a = txt:match(ARMOR_PAT)
      if a then armor = ns.Num(tonumber((a:gsub("[,%.]", "")))) end
      local d = txt:match(DPS_PAT)
      if d then dps = ns.Num(tonumber((d:gsub(",", ".")))) end
    end
  end
  return armor, dps
end

local function Read(link)
  local c = cache[link]
  if c then return c end
  local fn = (C_Item and C_Item.GetItemStats) or rawget(_G, "GetItemStats")
  local ok, st = false, nil
  if type(fn) == "function" then ok, st = pcall(fn, link) end
  if not ok or type(st) ~= "table" then return nil end -- not loaded yet: unknown, not cached
  local instant = (C_Item and C_Item.GetItemInfoInstant) or rawget(_G, "GetItemInfoInstant")
  local iok, _, _, _, equipLoc, _, classID, sub
  if type(instant) == "function" then iok, _, _, _, equipLoc, _, classID, sub = pcall(instant, link) end
  if not iok then equipLoc, classID, sub = nil, nil, nil end
  local info = (C_Item and C_Item.GetItemInfo) or rawget(_G, "GetItemInfo") or function() end
  local lok, name, _, _, ilvl = pcall(info, link)
  c = {}
  for i, key in ipairs(STAT_KEYS) do c[i] = ns.Num(st[key]) or 0 end
  c.ap = ns.Num(st.ITEM_MOD_ATTACK_POWER_SHORT) or 0
  c.rap = ns.Num(st.ITEM_MOD_RANGED_ATTACK_POWER_SHORT) or 0
  c.armor = ns.Num(st.RESISTANCE0_NAME) or 0
  c.dps = ns.Num(st.ITEM_MOD_DAMAGE_PER_SECOND_SHORT) or 0
  classID, sub = ns.Num(classID), ns.Num(sub)
  c.weapon = classID == WEAPON
  c.wand = c.weapon and sub == WAND
  c.ranged = c.weapon and (RANGED_SUB[sub or -1] or equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT"
    or equipLoc == "INVTYPE_THROWN") and not c.wand or false
  if (c.armor == 0 and not c.weapon) or (c.weapon and c.dps == 0) then
    local a, d = TipNumbers(link)
    if c.armor == 0 and a then c.armor = a end
    if c.weapon and c.dps == 0 and d then c.dps = d end
  end
  c.thrown = c.weapon and (sub == 16 or equipLoc == "INVTYPE_THROWN")
  c.ilvl = lok and ns.Num(ilvl) or 0
  -- (Kritikrunde) unknown until the client knows the item: stats read before that may still be empty
  if not (lok and type(name) == "string") then return nil end
  if cacheN >= 400 then cache, cacheN = {}, 0 end
  cache[link], cacheN = c, cacheN + 1
  return c
end
function ns.GearClearCache() cache, cacheN = {}, 0 Forget() end -- (tests)

-- What one point of armor is worth in Stamina for the player now (see the head of the file).
function ns.GearArmorStamina(level, health, armor)
  if level == nil and health == nil and armor == nil and mine.armorSta then return mine.armorSta end
  local own = level == nil and health == nil and armor == nil
  level = level or ns.Num(ns.Value(UnitLevel, "player")) or 1
  health = health or ns.Num(ns.Value(UnitHealthMax, "player"))
  if armor == nil then
    local ok, _, eff = pcall(UnitArmor or function() end, "player")
    armor = ok and ns.Num(eff) or 0
  end
  local L = level < 60 and level or level + 4.5 * (level - 59)
  local K = 400 + 85 * L
  local known = health and health > 0
  if not known then health = 20 * level + 40 end -- the client did not say: about a levelling character
  local v = health / (10 * (armor + K))
  if own and known then mine.armorSta = v end
  return v
end

-- Value of an item (link) for the player: total, then the parts stats (with AP), armor, dps. nil while unknown
-- (the item is not loaded yet, or the class is unknown).
function ns.GearValue(link, w, class, armorSta)
  if type(link) ~= "string" then return nil end
  if not w then w, class = ns.GearWeights() end
  if not w then return nil end
  local c = Read(link)
  if not c then return nil end
  local stats = 0
  for i = 1, 5 do stats = stats + (w[i] or 0) * c[i] end
  local meleeAP = (w[1] or 0) / (AP_PER_STR[class] or 1)
  local rangedAP = class == HUNTER and (w[2] or 0) / 2 or 0
  stats = stats + c.ap * (class == HUNTER and rangedAP or meleeAP) + c.rap * rangedAP
  local dps = 0
  if c.weapon and not c.wand then
    if c.ranged then dps = (class == HUNTER and not c.thrown) and 14 * rangedAP * c.dps or 0
    else dps = 14 * meleeAP * c.dps end
  end
  local armor = c.armor * (armorSta or ns.GearArmorStamina()) * (w[3] or 0)
  return stats + dps + armor, stats, armor, dps
end

-- Sum over a side: a link, a list of links (a two-hand weapon against both hands), or nil (an empty slot: 0).
-- Returns value, dps, ilvl, wand (the side is one wand), known.
local function Side(x, w, class, armorSta)
  if x == nil then return 0, 0, 0, false, true end
  if type(x) == "string" then
    local v = ns.GearValue(x, w, class, armorSta)
    if not v then return nil end
    local c = Read(x)
    return v, c.dps, c.ilvl, c.wand, true
  end
  local v, d, l, n = 0, 0, 0, 0
  for _, link in ipairs(x) do
    local a = ns.GearValue(link, w, class, armorSta)
    if not a then return nil end
    local c = Read(link)
    v, d, l, n = v + a, d + c.dps, l + c.ilvl, n + 1
  end
  return v, d, n > 0 and l / n or 0, false, true
end

-- Is a better than b for the player? a, b: a link, a list of links, or nil (nothing worn there).
-- Returns 1, -1 or 0 (alike in value, DPS and item level), then the value gain a - b; nil while either is unknown.
-- Wand against wand: the DPS decides when it differs by 5 % or more. Otherwise the value; when the values are alike,
-- the DPS, then the item level.
function ns.GearCompare(a, b)
  local w, class = ns.GearWeights()
  if not w then return nil end
  local armorSta = ns.GearArmorStamina()
  local va, da, la, wa = Side(a, w, class, armorSta)
  if not va then return nil end
  local vb, db, lb, wb = Side(b, w, class, armorSta)
  if not vb then return nil end
  local gain = va - vb
  if wa and wb and math.max(da, db) > 0 and math.abs(da - db) >= WAND_DPS_SHARE * math.max(da, db) then
    return da > db and 1 or -1, gain
  end
  if math.abs(gain) >= 0.01 then return gain > 0 and 1 or -1, gain end
  if math.abs(da - db) >= 0.01 then return da > db and 1 or -1, gain end
  if la ~= lb then return la > lb and 1 or -1, gain end
  return 0, gain
end
