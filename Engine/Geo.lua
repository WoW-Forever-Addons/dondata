local _, ns = ...

---------------------------------------------------------------------------
-- (30.10.2026, DONCORE_PLAN.md "DonData Lese-Engine" L3) World positions and distances, moved here from Questdon's
-- Arrow.lua: the reading engine needs them (nearest quests, points near the player, offers near a turn-in) also
-- without Questdon. Questdon's arrow uses the same functions (ns.WorldPos, ns.PlayerWorld, ns.DistanceFrom,
-- ns.TargetWorld, ns.DistanceAndBearing).
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Geometry
---------------------------------------------------------------------------
-- World position (yards) of a map point: continentID, north, west. The
-- client's answer, two vector tables per call.
local function AskWorldPos(mapID, x, y)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local ok, continent, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
  if not ok or not ns.Num(continent) or type(pos) ~= "table" or not pos.GetXY then return nil end
  local ok2, wx, wy = pcall(pos.GetXY, pos)
  if not ok2 or not (ns.Num(wx) and ns.Num(wy)) then return nil end
  return continent, wx, wy
end

-- (1.23) A map is an axis-aligned rectangle in the world, so its world
-- position is linear in x and y (what HereBeDragons does with the map's
-- corners). Per map, the client is asked for three corners once and every
-- point after that is arithmetic: no vectors per call (arrow 33 times a
-- second, minimap 10 times, every pin of a rebuild). The first real point
-- of a map is checked against the client; a map that does not fit (or any
-- unreadable answer) keeps asking the client. Replacing the client
-- function (another addon) starts over.
local transforms, transformFn = {}, nil
local NONLINEAR = false
local function Transform(mapID)
  local fn = C_Map and C_Map.GetWorldPosFromMapPos
  if fn ~= transformFn then transforms, transformFn = {}, fn end
  local t = transforms[mapID]
  if t ~= nil then return t end
  local c0, n0, w0 = AskWorldPos(mapID, 0, 0)
  local c1, n1, w1 = AskWorldPos(mapID, 1, 0)
  local c2, n2, w2 = AskWorldPos(mapID, 0, 1)
  if not (c0 and c1 and c2) or c0 ~= c1 or c0 ~= c2 then return nil end -- not cached: ask again next time
  t = { c = c0, n0 = n0, w0 = w0, nx = n1 - n0, wx = w1 - w0, ny = n2 - n0, wy = w2 - w0, checked = false }
  transforms[mapID] = t
  return t
end
function ns.WorldPos(mapID, x, y)
  mapID, x, y = ns.Num(mapID), ns.Num(x), ns.Num(y)
  if not (mapID and x and y) then return nil end
  local t = Transform(mapID)
  if not t then return AskWorldPos(mapID, x, y) end
  local n, w = t.n0 + x * t.nx + y * t.ny, t.w0 + x * t.wx + y * t.wy
  if not t.checked then
    t.checked = true
    local c, an, aw = AskWorldPos(mapID, x, y)
    if c ~= t.c or not an or math.abs(an - n) > 0.5 or math.abs(aw - w) > 0.5 then
      transforms[mapID] = NONLINEAR
      return c, an, aw
    end
  end
  return t.c, n, w
end

-- (16.10. evening, /qd mem) The other way round: the map position (0-1) of a world position on mapID, nil when the
-- map's corners are not known or it is another continent. For the player's position from UnitPosition (Core.lua).
function ns.MapFromWorld(mapID, c, n, w)
  local t = Transform(mapID)
  if not t or t.c ~= c then return nil end
  local det = t.nx * t.wy - t.ny * t.wx
  if det == 0 then return nil end
  local dn, dw = n - t.n0, w - t.w0
  return (dn * t.wy - t.ny * dw) / det, (t.nx * dw - dn * t.wx) / det
end

local function PlayerWorld()
  local mapID, x, y = ns.PlayerPosition()
  if not mapID then return nil end
  return ns.WorldPos(mapID, x, y)
end

-- World position of the last target asked for: the arrow asks for the same
-- target many times per second, and targets do not move.
local cT, cMap, cX, cY, cC, cN, cW
local function TargetWorld(target)
  -- (Questdon review 4) the quest list's cached points carry their world position (worked out once)
  if target._wc then return target._wc, target._wn, target._ww end
  if cT == target and cMap == target.mapID and cX == target.x and cY == target.y then return cC, cN, cW end
  local tc, tn, tw = ns.WorldPos(target.mapID, target.x, target.y)
  if tc then cT, cMap, cX, cY, cC, cN, cW = target, target.mapID, target.x, target.y, tc, tn, tw end
  return tc, tn, tw
end

local function FromPlayer(pc, pn, pw, target)
  if not (pc and target and target.mapID and target.x and target.y) then return nil end
  local tc, tn, tw = TargetWorld(target)
  if not tc or pc ~= tc then return nil end
  local north, east = tn - pn, -(tw - pw)
  local dist = math.sqrt(north * north + east * east)
  local bearing = math.atan2 and math.atan2(east, north) or math.atan(east, north)
  return dist, bearing
end

-- distance (yards) and bearing (radians, clockwise from north) from player to target
function ns.DistanceAndBearing(target)
  local pc, pn, pw = PlayerWorld()
  return FromPlayer(pc, pn, pw, target)
end

-- (18.10., Daniel: needle front and back wrong after the flight Stormwind to Westfall) one line for /qd diag: where
-- the player is (map, map position, world position, how it was read), where the target is, and the numbers the
-- needle turns by (bearing clockwise from north, facing counter-clockwise from north, both in degrees).

-- (1.23) For lists of targets: the player's world position once
-- (ns.PlayerWorld), then ns.DistanceFrom(pc, pn, pw, target) per target.
ns.PlayerWorld = PlayerWorld
ns.TargetWorld = TargetWorld -- (L3) Questdon's arrow diagnostics (Arrow.lua ns.NeedleDiag)
function ns.DistanceFrom(pc, pn, pw, target)
  return FromPlayer(pc, pn, pw, target)
end
