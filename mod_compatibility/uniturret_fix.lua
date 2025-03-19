------------------------------------------------------------------------------------
--                    Compatibility with "Universal Turret_fix"                   --
--    If this mod is installed, universal turrets should be able to attack our    --
--    dummies. So, remove the dummies from the ignore list of Uniturret's water   --
--    turrets and add them to their attack_target_mask instead!                   --
------------------------------------------------------------------------------------
local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")
WT.dprint("Checking for \"uniturret_Fix\".")

if mods["uniturret_Fix"] then
  WT.dprint("\"uniturret_Fix\" %s has been found.", {mods["uniturret_Fix"]})

  local add_ignore, add_attack, uniturret

  for t, turret in ipairs({"water", "water-locked"}) do

    add_ignore = true
    uniturret = data.raw["ammo-turret"]["uniturret-" .. turret]

    WT.show("Changing properties of", uniturret and uniturret.name or "nil")

    for m, mask in pairs(uniturret and uniturret.ignore_target_mask or {}) do
  WT.dprint("m: %s\tmask: %s", {m, mask})

      -- Remove dummies from ignore_target_mask
      if mask == WT.trigger_target_fire_dummy or mask == WT.trigger_target_acid_dummy then
        uniturret.ignore_target_mask[m] = nil
      end

      -- Check if we need to add our ignored entities to ignore_target_mask
      if mask == WT.trigger_target_ignore then
        add_ignore = false
        break
      end
    end

    if add_ignore then
      table.insert(uniturret.ignore_target_mask, WT.trigger_target_ignore)
    end

    WT.show("uniturret ignore_target_mask", uniturret.ignore_target_mask)


    -- Add dummies to attack_target_mask
    for d, dummy in ipairs({WT.trigger_target_fire_dummy, WT.trigger_target_acid_dummy}) do
      add_attack = true
      for m, mask in pairs(uniturret.attack_target_mask or {}) do
    WT.dprint("m: %s\tmask: %s", {m, mask})

        -- Check if dummies are already in attack_target_mask of turret
        if mask == dummy then
          add_attack = false
          break
        end
      end

      -- Add dummies to attack_target_mask
      if add_attack then
        table.insert(uniturret.attack_target_mask, dummy)
      end
    end

    WT.show("uniturret attack_target_mask", uniturret.attack_target_mask)
  end
end
