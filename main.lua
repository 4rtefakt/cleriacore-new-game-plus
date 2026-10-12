-- New Game+: a finished game leaves a legacy; the next new game starts from it, one cycle higher.
-- The legacy is a small file outside the saves; the cycle of a game is kept in its own save.

local S, P, G = cleria.settings, cleria.player, cleria.game

local enabled = S.get("Enabled", true)
local keep_level = S.get("KeepLevel", 50)      -- percent of the level carried over
local keep_sp = S.get("KeepSp", 50)            -- percent of the SP
local keep_weapon = S.get("KeepWeapon", true)
local harder = S.get("Harder", 25)             -- percent per cycle: monsters hit harder and last longer

local legacy = cleria.json.decode(cleria.data.read("legacy.json") or "")   -- {cycle, level, sp, weapon, character}
if type(legacy) ~= "table" then legacy = nil end
local cycle = 0                                -- this game's cycle (0 = an ordinary game)
local apply_pending = false

local function mult() return 1 + harder / 100 * cycle end

cleria.events.on("load", function() cycle = math.tointeger(cleria.save.get("cycle", 0)) or 0 apply_pending = false end)
cleria.events.on("new_game", function()
    cycle = 0
    apply_pending = enabled and legacy ~= nil
end)

-- The legacy is applied at the first moment the player has the controls (not inside the opening scenes).
cleria.events.on("tick", function()
    if not apply_pending or not G.in_game() or G.frozen() or not cleria.save.ready() then return end
    apply_pending = false
    cycle = legacy.cycle
    cleria.save.set("cycle", cycle)
    local level = math.max(1, math.min(60, math.floor(legacy.level * keep_level / 100)))
    local sp = math.floor(legacy.sp * keep_sp / 100)
    if level > P.level() then P.set_level(level) end
    if sp > 0 then P.add_sp(sp) end
    if keep_weapon and legacy.weapon > P.weapon_tier() then P.set_weapon_tier(legacy.weapon) end
    P.refresh()
    P.set_hp(P.max_hp())
    local text = string.format("Cycle %d: level %d, %d SP%s. Monsters hit %d%% harder.", cycle, P.level(), sp,
                               keep_weapon and ", your weapon" or "", math.floor((mult() - 1) * 100 + 0.5))
    cleria.notice(text, "New Game+")
    cleria.log(text)
end)

cleria.events.on("boss_defeated", function(e)
    local c = G.character()
    if not ((e.flag == 226 and c ~= 3) or e.flag == 227) then return end       -- Dalles for Yunica and Hugo, Darm for Toal
    legacy = {cycle = cycle + 1, level = P.level(), sp = P.sp(), weapon = P.weapon_tier(), character = c}
    cleria.data.write("legacy.json", cleria.json.encode(legacy))
    cleria.notice("Your next new game can start at cycle " .. legacy.cycle .. ".", "New Game+")
    cleria.log(string.format("legacy: cycle %d level %d sp %d weapon %d", legacy.cycle, legacy.level, legacy.sp, legacy.weapon))
end)

cleria.combat.add_filter("damage", function(q)
    if cycle == 0 or q.value <= 0 then return nil end
    if q.dir == "taken" then return math.floor(q.value * mult() + 0.5) end
    return math.max(1, math.floor(q.value / mult() + 0.5))
end)

cleria.hud.layer("ngplus", function(d)
    if cycle == 0 or not G.in_game() then return end
    local s = d.scale
    local text = "NG+" .. cycle
    local w = d:text_size(text, {size = 18 * s, font = "bold"})
    d:rect(d.w - w - 34 * s, d.h - 46 * s, w + 20 * s, 30 * s, {color = 0x100F0B, alpha = 0.7, rounding = 4 * s})
    d:text(d.w - w - 24 * s, d.h - 41 * s, text, {size = 18 * s, color = "gold", font = "bold"})
end)

cleria.ui.page("New Game+", function(p)
    p:section("New Game+")
    p:info("This game", cycle > 0 and ("cycle " .. cycle) or "an ordinary game",
           cycle > 0 and string.format("Monsters hit %d%% harder and take %d%% less.", math.floor((mult() - 1) * 100 + 0.5), math.floor((1 - 1 / mult()) * 100 + 0.5)) or "")
    p:info("Legacy", legacy and string.format("cycle %d: level %d, %d SP, weapon %d", legacy.cycle, legacy.level, legacy.sp, legacy.weapon) or "none yet",
           legacy and "From your last finished game. Your next new game starts from it." or "Finish the game once to leave a legacy.")
    local v, ch = p:toggle("Start new games from the legacy", enabled, "Off: a new game is an ordinary one. Not a retail option.")
    if ch then enabled = v S.set("Enabled", v) end
    p:section("What carries over")
    v, ch = p:slider("Level", keep_level, 0, 100, 5, "%.0f%%", "The share of your level you keep.")
    if ch then keep_level = math.floor(v + 0.5) S.set("KeepLevel", keep_level) end
    v, ch = p:slider("SP", keep_sp, 0, 100, 5, "%.0f%%", "The share of your SP you keep.")
    if ch then keep_sp = math.floor(v + 0.5) S.set("KeepSp", keep_sp) end
    v, ch = p:toggle("Weapon", keep_weapon, "Your weapon keeps its upgrades.")
    if ch then keep_weapon = v S.set("KeepWeapon", v) end
    p:section("The tower")
    v, ch = p:slider("Harder per cycle", harder, 0, 100, 5, "%.0f%%", "Each cycle, monsters and bosses hit this much harder and take this much less.")
    if ch then harder = math.floor(v + 0.5) S.set("Harder", harder) end
    if p:button("Forget the legacy", {desc = "The next new game is an ordinary one.", enabled = legacy ~= nil}) then
        legacy = nil
        cleria.data.remove("legacy.json")
    end
end)

cleria.speedrun.modification(function() return "New Game+" .. (cycle > 0 and (" cycle " .. cycle) or "") end)
cleria.command("ng", function(a)
    if tonumber(a) then P.set_weapon_tier(tonumber(a)) P.refresh() end       -- "ng <tier>": a weapon for the tests
    local st = P.stats()
    cleria.log(string.format("cycle %d lv %d sp %d weapon %d hp %.0f/%.0f legacy %s", cycle, st.level, st.sp, st.weapon_tier, st.hp, st.max_hp,
                             legacy and ("cycle " .. legacy.cycle) or "none"))
end)
cleria.log("New Game+ loaded" .. (legacy and (": a legacy of cycle " .. legacy.cycle .. " is waiting") or ""))
