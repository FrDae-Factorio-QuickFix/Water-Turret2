local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")
local MOD_PIX = WT.mod_root .. "graphics/"

local mod_name = "\"Hardened pipes\""
WT.dprint("Checking for %s", {mod_name})


------------------------------------------------------------------------------------
--                   Compatibility with "Hardened pipes"                      --
------------------------------------------------------------------------------------
if mods["hardened_pipes"] and WT.hardened_pipes then

  --~ local IMG_PATH = WT.mod_root .. "graphics/new/"
  local i_type, i_name, i_amount

  local function find_pipes(ingredients)
    for i, ingredient in pairs(ingredients) do
      if (table_size(ingredient) == 2 and ingredient[1] == "pipe") or
          (table_size(ingredient) == 3 and ingredient.name == "pipe") then
        return i
      end
    end
    return nil
  end

  local WT_recipe = data.raw.recipe[WT.water_turret_name]
  local FE_recipe = data.raw.recipe[WT.extinguisher_turret_name]

------------------------------------------------------------------------------------
-- Change recipe ingredients and results
  local results, pipes

  local recipe_data_normal = FE_recipe and FE_recipe.normal
  local recipe_data_expensive = FE_recipe and FE_recipe.expensive

  for m, mode in pairs({"normal", "expensive", ""}) do
    local ingredients = mode ~= "" and
                        FE_recipe[mode] and FE_recipe[mode].ingredients or
                        FE_recipe.ingredients
    local pipes = mode ~= "" and
                  find_pipes(WT_recipe[mode] and WT_recipe[mode].ingredients or {}) or
                  find_pipes(WT_recipe.ingredients or {})

    -- Replace ingredients (Shouldn't be necessary, but perhaps other mods have
    -- changed something.)
    local replaced = false
    for i, ingredient in pairs(ingredients) do
      if ingredient.name == "pipe" then
        ingredient.name = "PCHP-hardened-pipe"
        replaced = true
      end
--~ WT.dprint("ingredients in mode " .. mode .. ": " .. serpent.block(ingredients))
    end

    local amount = mode ~= "" and WT_recipe[mode].ingredients[pipes].amount or
                                    WT_recipe.ingredients[pipes].amount
    -- Add hardened pipes otherwise
    if not replaced then
      pipes = mode ~= "" and find_pipes(WT_recipe[mode].ingredients or {}) or
                              find_pipes(WT_recipe.ingredients or {})
      table.insert(ingredients, {
        type = "item",
        name = "PCHP-hardened-pipe",
        amount = amount
      })
    end

    -- We replace the normal pipes in the water turrets with hardened pipes,
    -- so as many pipes as went into the water turret should be returned with
    -- the fire extinguisher turret.
    -- Convert "result"/"result_count" to "results"
    if mode ~= "" then
      results = FE_recipe[mode].results or {{
        type = "item",
        name = FE_recipe[mode].result,
        amount = FE_recipe[mode].result_count
      }}
    else
      results = FE_recipe.results or {{
        type = "item",
        name = FE_recipe.result,
        amount = FE_recipe.result_count
      }}
    end


    -- Add pipes to "results"
    local x = mode ~= "" and find_pipes(FE_recipe[mode].results or {}) or
                             find_pipes(FE_recipe.results or {})
    if mode ~= "" then
      if x then
        FE_recipe[mode].results[x].amount = amount
      else
        FE_recipe[mode].results = FE_recipe[mode].results or results
        table.insert(FE_recipe[mode].results, {
          type = "item",
          name = "pipe",
          amount = amount
        })
      end
      FE_recipe[mode].main_product = WT.extinguisher_turret_name
      FE_recipe[mode].result = nil
      FE_recipe[mode].result_count = nil

    else
      if x then
        FE_recipe.results[x].amount = amount
      else
        FE_recipe.results = FE_recipe.results or results
        table.insert(FE_recipe.results, {
          type = "item",
          name = "pipe",
          amount = amount
        })
      end
      FE_recipe.main_product = WT.extinguisher_turret_name
      FE_recipe.result = nil
      FE_recipe.result_count = nil
    end
  end
  -- Remove obsolete recipe data from prototype root
  FE_recipe.ingredients = FE_recipe.normal.ingredients
  FE_recipe.main_product = FE_recipe.normal.main_product
  FE_recipe.results = FE_recipe.normal.results
  FE_recipe.result = nil
  FE_recipe.result_count = nil
  data:extend({ FE_recipe })
  --~ WT.show("Recipe Fire extinguisher turret", data.raw.recipe[WT.extinguisher_turret_name])
  WT.dprint("%s %s has been found. Added hardened pipes to recipe of %s!",
            {mod_name, mods["hardened_pipes"], FE_recipe.name})

  ------------------------------------------------------------------------------------
  -- Replace animations for turret base
  --~ WT.exchange_images({ "north", "east", "south", "west" },
                      --~ "extinguisher-turret-hardened-base-%NAME%.png",
                      --~ data.raw[WT.turret_type][WT.extinguisher_turret_name].base_picture)

  local layer
  for d, direction in ipairs({"north", "east", "south", "west"}) do
    layer = data.raw[WT.turret_type][WT.extinguisher_turret_name].base_picture[direction].layers[1]

    layer.filename = MOD_PIX .. "hr-turret-base-pipes-" .. direction .. ".png"

  end
  WT.dprint("%s %s has been found. Exchanged graphics of %s!",
            {mod_name, mods["hardened_pipes"], WT.extinguisher_turret_name})

  ------------------------------------------------------------------------------------
  -- Add new prerequisite to technology
  tech = data.raw.technology["WT-fire-ex-turret"]
  local found = false
  for p, prerequisite in pairs(tech.prerequisites or {}) do
    if prerequisite == "PCHP-hardened-pipes" then
      found = true
      break
    end
  end
  if not found then
    table.insert(tech.prerequisites, "PCHP-hardened-pipes")
  end
  --~ WT.dprint("Prerequisites of %s: %s", {
    --~ data.raw.technology["WT-fire-ex-turret"].name,
    --~ data.raw.technology["WT-fire-ex-turret"].prerequisites,
  --~ })

  WT.dprint("%s %s has been found. Added hardened pipes to prerequisites of %s!",
            {mod_name, mods["hardened_pipes"], tech.name})

  ------------------------------------------------------------------------------------
  -- As compensation for the later unlock, the turrets inherit all resistancies from
  -- hardened pipes. If they already are resistant against one of the damages, the
  -- resistancy values will get the values that mean more protection.
  local hp_resistances = data.raw.pipe["PCHP-hardened-pipe"].resistances
  local turret_resistances


  for v, variety in ipairs({WT.extinguisher_turret_name, WT.extinguisher_turret_water_name}) do
    turret_resistances = data.raw[WT.turret_type][variety].resistances
    turret_resistances = turret_resistances or {}


    for hr, hp_resistance in pairs(hp_resistances or {}) do
      local found = false
      for tr, turret_resistance in pairs(turret_resistances) do
        if hp_resistance.type == turret_resistance.type then
          if hp_resistance.decrease and turret_resistance.decrease then
--~ WT.show("hp_resistance.decrease and turret_resistance.decrease", {hp_resistance.decrease and turret_resistance.decrease})
            turret_resistance.decrease =
              (hp_resistance.decrease > turret_resistance.decrease) and
              hp_resistance.decrease or turret_resistance.decrease
--~ WT.show("hp_resistance.decrease and turret_resistance.decrease", {hp_resistance.decrease and turret_resistance.decrease})
          end

          if hp_resistance.decrease and turret_resistance.decrease then
--~ WT.show("hp_resistance.percent and turret_resistance.percent", {hp_resistance.percent and turret_resistance.percent})
            turret_resistance.percent =
              (hp_resistance.percent > turret_resistance.percent) and
              hp_resistance.percent or turret_resistance.percent
--~ WT.show("hp_resistance.percent and turret_resistance.percent", {hp_resistance.percent and turret_resistance.percent})
          end
          WT.dprint("Changed resistance: " .. serpent.line(turret_resistance))
          found = true
          break
        end
      end
      if not found then
        turret_resistances[#turret_resistances + 1] = hp_resistance
        WT.dprint("Added resistance: " .. serpent.line(hp_resistance))
      end


    -- Show off the resistances!
    data.raw[WT.turret_type][variety].hide_resistances = false

    WT.dprint("%s %s has been found. Added resistances to %s!",
              {mod_name, mods["hardened_pipes"], WT.extinguisher_turret_name})
    end
  end
end
