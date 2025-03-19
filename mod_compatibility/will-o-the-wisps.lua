local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")

------------------------------------------------------------------------------------
--                     Compatibility with "Will-o'-the-wisps"                     --
------------------------------------------------------------------------------------

WT.dprint("Checking for \"Will-o-the-Wisps_updated\" and friends")

-- Add wisps to ignore_target_mask of our turrets
local mod_name =
  (mods["Will-o-the-Wisps_updated"] and
    {"Will-o'-the-Wisps updated", mods["Will-o-the-Wisps_updated"]}) or
  (mods["Will-o-the-Wisps_updated-2"] and
    {"Will-o'-the-Wisps updated (2)", mods["Will-o-the-Wisps_updated-2"]}) or
  (mods["The_Night_Has_A_Thousand_Eyes"] and
    {"The Night Has A Thousand Eyes", mods["The_Night_Has_A_Thousand_Eyes"]})

if mod_name then

  -- Red wisps will replicate if killed, slowing down everything. Better we don't
  -- attack them!'
    local wisp = data.raw.unit["wisp-red"]

    -- Trigger target mask
    wisp.trigger_target_mask = wisp.trigger_target_mask or {}
    table.insert(wisp.trigger_target_mask, WT.trigger_target_ignore)

    -- Resistances

    -- (Removed for now -- some random splash damage may make things more interesting!)
    --~ local resistances = {
      --~ { type = WT.steam_damage_name, decrease = 0, percent = 100 },
      --~ { type = WT.water_damage_name, decrease = 0, percent = 100 },
      --~ { type = WT.fire_ex_damage_name, decrease = 0, percent = 100 },
    --~ }
    --~ local insert = true
    --~ wisp.resistances = wisp.resistances or {}

    --~ for r, resistance in ipairs(resistances) do
      --~ for k, v in pairs(wisp.resistances) do
        --~ if v.type == resistance.type then
          --~ insert = false
          --~ wisp.resistances[k] = resistance
          --~ break
        --~ end
      --~ end
      --~ if insert then
        --~ table.insert(wisp.resistances, resistance)
      --~ end
    --~ end
    --~ WT.dprint("trigger_target_mask of %s wisps: %s",
              --~ {color, wisp.trigger_target_mask})
--~ WT.show("wisp attack mask", wisp.attack_target_mask)
--~ WT.show("wisp ignore mask", wisp.ignore_target_mask)
--~ WT.show("wisp resistances", wisp.resistances)



  WT.dprint("\"%s\" %s has been found. Red wisps are now ignored by our turrets!",
            {mod_name[1], mod_name[2]})
end
