local WT = require('__WaterTurret__/common')("WaterTurret")
local MOD_PIX = WT.mod_root .. "graphics/"

data:extend({
  {
    type = "technology",
    name = "WT-fire-ex-turret",
    localised_name = WT.hardened_pipes and
      {"technology-name." .. WT.extinguisher_turret_name .. "-hardened"} or
      {"technology-name." .. WT.extinguisher_turret_name},
    localised_description = WT.hardened_pipes and
      {"technology-description." .. WT.extinguisher_turret_name .. "-hardened"} or
      {"technology-description." .. WT.extinguisher_turret_name},
    icon_size = 128,
    icon_mipmaps = 0,
    --~ icon = MOD_PIX .. "extinguisher-tech-icon.png",
    icons = {
      {
        icon = MOD_PIX .. "extinguisher-tech-icon-2.png",
        tint = WT.extinguisher_turret_tint
      }
    },
    effects = {
      {
        type = "unlock-recipe",
        recipe = WT.extinguisher_turret_name
      },
    },
    prerequisites = {"lubricant"},
    unit = {
      count = 100,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1},
      },
      time = 75
    }
  }
})


-- Add recipe unlock for steam/water turrets to technology "turrets"
local unlock_tech = data.raw.technology["turrets"]
if not WT.unlocked_already(unlock_tech, WT.water_turret_name) then

  unlock_tech.effects = unlock_tech.effects  or {}
  table.insert(unlock_tech.effects, {
    ["recipe"] = WT.water_turret_name,
    ["type"] = "unlock-recipe"
  })
  WT.dprint("Added recipe for %s to recipes unlocked by technology %s!",
            {WT.water_turret_name, unlock_tech.name}, "line")

end
