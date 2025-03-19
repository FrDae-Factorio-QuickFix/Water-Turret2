------------------------------------------------------------------------------------
--                  Compatibility with "Fire Department QuickFix"                 --
--  This mod defines its own variety of water ("fide-water"). Our dummies will be --
--  removed if a fire is removed with that. But if Uniturrets is also active, the --
--  water can be used as ammo for a variety of those turrets and these should be  --
--  able to attack our dummies directly. So we add our own damage to the stream.  --
--  We should also make our turrets immune to damage from "fide-water".
------------------------------------------------------------------------------------

local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")

WT.dprint("Checking for stream from \"Fire Department QuickFix\" and friends.")

-- Add our damage to water-turret from Fire Department

-- The fide-water-gun-stream can be provided by other mods as well, so just check if
-- the stream is available!
local stream = data.raw.stream["fide-water-gun-stream"]

if stream then
  WT.dprint("\"fide-water-gun-stream\" has been found.")
  local new_action = {
    type = "direct",
    action_delivery = {
      type = "instant",
      target_effects = {
        {
          type = "damage",
          damage = {
            type = WT.water_damage_name,
            -- Apply just the base damage amount -- there must be an incentive to
            -- use our own turrets, and that is the bonus from water_pressure!
            --~ amount = WT.water_base_damage_amount * water_pressure_factor,
            amount = WT.water_base_damage_amount,
          },
          apply_damage_to_trees = false
        }
      }
    }
  }
  table.insert(stream.action, new_action)
  WT.show("stream.action", stream.action)
  WT.dprint("Added %s damage to effects of Fire Department's water stream.", {WT.water_damage_name})
end

-- Make our turrets immune to damage from "fide-water"
if data.raw["damage-type"]["fide-water"] then
  local add_resistance = true
  local resistances

  --~ WT.dprint()
  for turret, t in pairs(WT.turret_names) do
    resistances = data.raw[WT.turret_type][turret].resistances
    WT.dprint("turret: %s\tresistances: %s", {turret, resistances})

    for r, resistance in ipairs(resistances or {}) do
      WT.dprint("r: %s\tresistance: %s", {r, resistance})
      if resistance.type == "fide-water" then
        resistances[r].decrease = 0
        resistances[r].percent = 100
        add_resistance = false
        WT.dprint("Changed resistance of %s against %s.", {turret, resistance.type})
      end
    end
    if add_resistance then
      table.insert(resistances, {type = "fide-water", decrease = 0, percent = 100})
      WT.dprint("Added resistance against \"fide-water\" to %s.", {turret})
    end
  end
end
