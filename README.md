# New Game+

For **Ys Origin** on CleriaCore. Finish the game, then start again **stronger, against a harder tower**.

- When Dalles (Yunica, Hugo) or Darm (Toal) falls, the mod writes a **legacy**: your level, your SP, your weapon.
- Your next **new game** starts from it, one **cycle** higher: half your level and half your SP by default, and your
  weapon with its upgrades.
- Each cycle, monsters and bosses **hit 25% harder and take 25% less**. Finish cycle 1 and the next game is cycle 2.
- A small **NG+2** mark in the corner shows the cycle. The cycle belongs to that save; ordinary saves are untouched.

Everything is a setting in **F1 > Mods > New Game+**: what share of the level and SP carries over, whether the
weapon does, how much harder each cycle is, and a switch to start an ordinary game instead. *Forget the legacy*
erases it.

## Install

1. Download `4rtefakt.ngplus-1.0.0.cleriamod` from the [releases](../../releases).
2. Double-click it (or use F1 > Mods > *Install a mod file...*).
3. Turn **New Game+** on in F1 > Mods and restart CleriaCore.

Needs a CleriaCore with mod API 6.

## How it works

One Lua file, [main.lua](main.lua), about 120 lines. Two kinds of storage do the work: a file of the install for
what passes from one game to the next, and the save itself for what belongs to one game.

```lua
cleria.events.on("boss_defeated", function(e)                  -- the last boss: leave a legacy
    if not ((e.flag == 226 and G.character() ~= 3) or e.flag == 227) then return end
    legacy = {cycle = cycle + 1, level = P.level(), sp = P.sp(), weapon = P.weapon_tier()}
    cleria.data.write("legacy.json", cleria.json.encode(legacy))
end)

-- a new game, at the first moment the player has the controls
cycle = legacy.cycle
cleria.save.set("cycle", cycle)
P.set_level(math.floor(legacy.level * keep_level / 100))
P.add_sp(math.floor(legacy.sp * keep_sp / 100))
P.set_weapon_tier(legacy.weapon)
```

| Part | API |
|---|---|
| The ending | `boss_defeated` with its flag, `game.character()` |
| From one game to the next | `cleria.data` (`read`, `write`, `remove`) |
| The cycle of a game | `cleria.save` |
| Starting stronger | `player.set_level`, `add_sp`, `set_weapon_tier`, `refresh`, `set_hp` |
| The harder tower | the `"damage"` combat filter, both directions |

## Tests

`python .dev/run.py` runs three cases through CleriaCore's headless harness: a game finished at level 40 with
30 000 SP and a tier 6 weapon leaves its legacy, and the next start of the game is cycle 1 at level 20 with 15 000
SP and the weapon, where a hit of 15 does 19 and the cycle survives a save and load; finishing that game leaves a
legacy of cycle 2; with no legacy nothing happens.

Not covered: a real ending (the tests set the boss's flag), a start through the real opening scenes, and the balance:
25% a cycle and half the level are first guesses.

## About

Written with AI assistance (Claude Code) as a showcase of the CleriaCore mod API, and tested as described above.
MIT license.
