local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")
local MOD_PIX = WT.mod_root .. "graphics/icons/"

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                     Recipes                                    --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- For the fluid recipes, we need to consider 3 cases:
-- 1) BI adds a new recipe. Increase emissions of default recipes!
-- 2) BI is active but doesn't add a new recipe. Exchange default against BI recipe!
-- 3) Default recipes are used.

local BI = mods["Bio_Industries"] and true or false


------------------------------------------------------------------------------------
-- Change alpha channel
local function change_alpha(color, new_alpha)
  if not (color and type(color) == "table") then
    error(string.format("%s is not a valid color!", color))
  end
  if not (new_alpha and type(new_alpha) == "number" and
            new_alpha >= 0 and new_alpha <=1) then
    error(string.format("%s is not a valid value for alpha!", new_alpha))
  end

  local new_c = table.deepcopy(color)
  -- Colors in short format with 4 numbers(rgba)
  if table_size(new_c) == 4 and not new_c.a then
    new_c[4] = new_alpha
  -- Colors in short format with  have 3  numbers (rgb)
  elseif table_size(new_c) == 3 and not (new_c.r or new_c.g or new_c.b or new_c.a) then
    new_c[4] = new_alpha
  -- We can use the name otherwise!
  else
    new_c.a = new_alpha
  end

  return new_c
end


------------------------------------------------------------------------------------
-- Make icons
local function make_recipe_icon(item)
  return {
    {
      icon = MOD_PIX .. "fluid/fire-ex-fluid-recipe-turret-bg.png",
      icon_size = 128,
      scale = 0.5
    },
    {
      icon = MOD_PIX .. "fluid/fire-ex-fluid-recipe-turret.png",
      tint = WT.extinguisher_turret_tint,
      icon_size = 128,
      scale = 0.5
    },
    {
      icon = MOD_PIX .. "fluid/fire-ex-fluid-recipe-fluid-bg.png",
      icon_size = 128,
      scale = 0.5
    },
    {
      icon = MOD_PIX .. "fluid/fire-ex-fluid-recipe-fluid.png",
      tint = WT.fire_ex_fluid_tint,
      icon_size = 128,
      scale = 0.5

    },
    {
      icon = MOD_PIX .. "fluid/fire-ex-fluid-recipe-ingredient-" .. item .. ".png",
      icon_size = 128,
      scale = 0.5
    },
  }
end


------------------------------------------------------------------------------------
-- Water turret
------------------------------------------------------------------------------------

local waterrecipe = util.table.deepcopy(data.raw["recipe"]["flamethrower-turret"])
waterrecipe.name = WT.water_turret_name
waterrecipe.localised_name = {"entity-name." .. WT.water_turret_name}
waterrecipe.localised_description = {"entity-description." .. WT.water_turret_name}
--~ waterrecipe.icon = MOD_PIX .. "water-turret-icon.png"
waterrecipe.icons = {
  {icon = MOD_PIX .."turret-icon.png", scale = 0.5, icon_size = 64},
  { icon = MOD_PIX .. "turret-icon-raw.png", tint = WT.water_turret_tint, scale = 0.5,   icon_size = 64 }
}
local recipe_data = {
  ["name"] = WT.water_turret_name,
  ["enabled"] = false,
  ["ingredients"] = {
    { type = "item", name = "iron-plate", amount = 30},
    { type = "item", name = "iron-gear-wheel", amount = 15 },
    { type = "item", name = "pipe",            amount = 10 },
    { type = "item", name = "offshore-pump",   amount = 1 }
  },

  ["results"] = {{type = "item", name = WT.water_turret_name, amount = 1}},
  ["energy_required"] = waterrecipe.energy_required
}

waterrecipe = WT.compile_recipe(waterrecipe, recipe_data)
data:extend({ waterrecipe })


------------------------------------------------------------------------------------
-- Fire extinguisher turret
------------------------------------------------------------------------------------

local extinguisherrecipe = util.table.deepcopy(data.raw["recipe"][WT.water_turret_name])
extinguisherrecipe.name = WT.extinguisher_turret_name
extinguisherrecipe.localised_name = WT.hardened_pipes and
  {"entity-name." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-name." .. WT.extinguisher_turret_name}
extinguisherrecipe.localised_description = WT.hardened_pipes and
  {"entity-description." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-description." .. WT.extinguisher_turret_name}
WT.dprint("Hardened pipes: %s\tlocalised name: %s", {WT.hardened_pipes, extinguisherrecipe.localised_name})

extinguisherrecipe.icons = {
  {icon = MOD_PIX .."turret-icon.png"},
  {icon = MOD_PIX .. "turret-icon-raw.png", tint = WT.extinguisher_turret_tint}
}
extinguisherrecipe.category = "crafting-with-fluid"

recipe_data = {
  ["name"] = WT.extinguisher_turret_name,
  ["enabled"] = false,
  ["ingredients"] = {
    {WT.water_turret_name, 1},
    { type = "item",        name = "steel-plate",  amount = 15 },
    { type = "item",        name = "iron-gear-wheel", amount = 30 },
    { type = "item",        name = "advanced-circuit", amount = 5 },
    {type = "fluid", name = "lubricant", amount = 50},
  },

  ["results"] = {{type = "item", name = WT.extinguisher_turret_name, amount = 1}},
  ["energy_required"] = extinguisherrecipe.energy_required * 3
}

extinguisherrecipe = WT.compile_recipe(extinguisherrecipe, recipe_data)

data:extend({extinguisherrecipe})

--~ WT.dprint("Recipe: %s", {data.raw.recipe[WT.extinguisher_turret_name]})

------------------------------------------------------------------------------------
-- Fire extinguisher fluid
------------------------------------------------------------------------------------
local recipe, recipe_data, recipe_data_expensive

-- We want the crafting machine animation to show different levels of pollution
-- created by the different fluid recipes.
local recipe_dirty_tint, recipe_OK_tint, recipe_clean_tint
local alpha_dirty, alpha_OK, alpha_clean = 1, .5, 0.25
local black = {r = 0, g = 0, b = 0}

recipe_dirty_tint = table.deepcopy(WT.fire_ex_fluid_tint)
--~ recipe_dirty_tint = change_alpha(recipe_dirty_tint, alpha_dirty)
recipe_OK_tint = table.deepcopy(WT.fire_ex_fluid_tint)
recipe_OK_tint = change_alpha(recipe_OK_tint, alpha_OK)
recipe_clean_tint = { r = 1, g = 1, b = 1, a = 1}


-- Make things more interesting: The fastest recipe with the highest yield will also
-- produce most pollution!
local base_energy_required = 15         -- Oil:  10     Charcoal:  22.5
local base_results_amount = 200         -- Oil: 300     Charcoal: 133
--~ local base_emissions_multiplier = WT.BI_adds_new_recipe and 2 or 1
local base_emissions_multiplier = 2
local bonus_malus = 1.5                 -- Oil: x*y x/y Charcoal: x/y x*y

-- Factor for expensive mode
local expensive = 1.5

------------------------------------------------------------------------------------
-- Recipe using oil

recipe = {
  type = "recipe",
  name = WT.fire_ex_fluid .. "-oil",
  --~ localised_description = {"recipe-description.WT-fire_ex_fluid"},
  icons = make_recipe_icon("oil"),
  icon_size = 128,
  category = "chemistry",
  subgroup = "fluid",
  ingredients = {},
  results = {},
  enabled = false,
  allow_as_intermediate = false,
  allow_decomposition = false,
  always_show_made_in = true,
  crafting_machine_tint = {
    primary = WT.fire_ex_fluid_tint,
    secondary = WT.fire_ex_fluid_tint,
    tertiary = change_alpha(black, alpha_dirty),
    quaternary = recipe_dirty_tint,
  },
  order = "WT-[fire-extinguisher-fluid]-1"
}

recipe_data = {
  energy_required = base_energy_required / bonus_malus,
    ingredients = {
      {type = "fluid", name = "water", amount = 100},
      {type = "fluid", name = "crude-oil", amount = 50},
      {type = "item", name = "sulfur", amount = 5},
    },
  results = {
    {type = "fluid", name = WT.fire_ex_fluid, amount = base_results_amount * bonus_malus},
  },
  main_product = WT.fire_ex_fluid,
  enabled = false,
  emissions_multiplier = 1.5 * base_emissions_multiplier * bonus_malus,
  always_show_made_in = true,
  allow_decomposition = false,
}
recipe_data_expensive = table.deepcopy(recipe_data)
recipe_data_expensive.energy_required = recipe_data.energy_required * expensive

data:extend({ WT.compile_recipe(recipe, recipe_data, recipe_data_expensive) })
WT.show("Fire-extinguisher fluid with crude oil", data.raw.recipe[WT.fire_ex_fluid .. "-oil"])


------------------------------------------------------------------------------------
-- Recipe using coal
local coal_recipe = table.deepcopy(data.raw.recipe[WT.fire_ex_fluid .. "-oil"])
coal_recipe.name = WT.fire_ex_fluid .. "-coal"
--~ coal_recipe.localised_description = {"recipe-description.WT-fire_ex_fluid"}
coal_recipe.order = "WT-[fire-extinguisher-fluid]-2"
coal_recipe.icons = make_recipe_icon("coal")
coal_recipe.crafting_machine_tint = {
  primary = WT.fire_ex_fluid_tint,
  secondary = WT.fire_ex_fluid_tint,
  tertiary = change_alpha(black, alpha_OK),
  quaternary = recipe_OK_tint,
}

local coal_recipe_data = table.deepcopy(recipe_data)
coal_recipe_data.energy_required = base_energy_required
coal_recipe_data.emissions_multiplier = base_emissions_multiplier * bonus_malus
coal_recipe_data.ingredients = {
  {type = "fluid", name = "water", amount = 100},
  {type = "fluid", name = "sulfuric-acid", amount = 50},
  {type = "item", name = "coal", amount = 25},
}
coal_recipe_data.results[1].amount = base_results_amount
local coal_recipe_data_expensive = table.deepcopy(coal_recipe_data)
coal_recipe_data_expensive.energy_required = coal_recipe_data.energy_required * expensive

data:extend({ WT.compile_recipe(coal_recipe, coal_recipe_data, coal_recipe_data_expensive) })

WT.show("Fire-extinguisher fluid with coal", data.raw.recipe[WT.fire_ex_fluid .. "-coal"])


------------------------------------------------------------------------------------
-- Recipe using charcoal
WT.show("Charcoal item", data.raw.item["wood-charcoal"] and data.raw.item["wood-charcoal"].name)
WT.show("Setting", WT.BI_adds_new_recipe)

-- Make recipe data if BI is active!
if BI then
  local charcoal_recipe = table.deepcopy(data.raw.recipe[WT.fire_ex_fluid .. "-oil"])
  charcoal_recipe.name = WT.fire_ex_fluid .. "-charcoal"
  --~ charcoal_recipe.localised_description = {"recipe-description.WT-fire_ex_fluid"}
  charcoal_recipe.order = "WT-[fire-extinguisher-fluid]-3"
  charcoal_recipe.icons = make_recipe_icon("charcoal")

  charcoal_recipe.crafting_machine_tint = {
    primary = WT.fire_ex_fluid_tint,
    secondary = WT.fire_ex_fluid_tint,
    tertiary = change_alpha(black, alpha_clean),
    quaternary = recipe_clean_tint,
  }
  local charcoal_recipe_data = table.deepcopy(recipe_data)
  charcoal_recipe_data.emissions_multiplier = 0.8
  charcoal_recipe_data.energy_required = base_energy_required * bonus_malus
  charcoal_recipe_data.ingredients = {
          {type = "fluid", name = "water", amount = 100},
          {type = "fluid", name = "sulfuric-acid", amount = 50},
          {type = "item", name = "wood-charcoal", amount = 50},
  }
  charcoal_recipe_data.results[1].amount = base_results_amount / bonus_malus
  local charcoal_recipe_data_expensive = table.deepcopy(charcoal_recipe_data)
  charcoal_recipe_data_expensive.energy_required = charcoal_recipe_data.energy_required * expensive


  recipe = WT.compile_recipe(charcoal_recipe, charcoal_recipe_data, charcoal_recipe_data_expensive)
  data:extend({recipe})
  WT.dprint("Made additional recipe for Fire extinguisher fluid with charcoal.")

  -- Remove coal
  if not WT.BI_adds_new_recipe then
    data.raw.recipe[WT.fire_ex_fluid .. "-coal"] = nil
    WT.dprint("Removed coal recipe!")
  end

  --~ WT.show("Charcoal recipe", data.raw.recipe[WT.fire_ex_fluid .. "-charcoal"])
end
