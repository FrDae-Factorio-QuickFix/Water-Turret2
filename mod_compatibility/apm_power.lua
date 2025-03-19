local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")

------------------------------------------------------------------------------------
--               Compatibility with "Amator Phasma's Coal & Steam"                --
------------------------------------------------------------------------------------

WT.dprint("Checking for \"Amator Phasma's Coal & Steam\".")

-- Change recipe ingredients
if mods["apm_power"] or mods["apm-power-notnotmelon"] then

  local recipe = util.table.deepcopy(data.raw["recipe"][WT.water_turret_name])

  local recipe_data_normal = {
    ["ingredients"] = {
      {"apm_mechanical_relay", 8},
      {"pipe", 12},
      {"apm_gearing", 5},
      {"apm_machine_frame_basic", 1}
    }
  }

  local recipe_data_expensive = {
    ["ingredients"] = {
      {"apm_mechanical_relay", 10},
      {"pipe", 18},
      {"apm_gearing", 10},
      {"iron-gear-wheel", 6},
      {"apm_machine_frame_basic", 1}
    },
  }

  data:extend({WT.compile_recipe(recipe, recipe_data_normal, recipe_data_expensive)})
  WT.dprint("\"Amator Phasma's Coal & Steam\" has been found. Water turrets now require ingredients from that mod!")
end
