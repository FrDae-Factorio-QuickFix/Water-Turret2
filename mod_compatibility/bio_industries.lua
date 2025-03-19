------------------------------------------------------------------------------------
--                       Compatibility with "Bio Industries"                      --
------------------------------------------------------------------------------------
local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")

WT.dprint("Checking for \"Bio Industries\".")

--~ log("Fire-extinguisher fluid with crude oil: " .. serpent.block(data.raw.recipe["WT-fire_ex_fluid-oil"]))

local tech = data.raw.technology["WT-fire-ex-turret"]
local unlocks = { WT.fire_ex_fluid .. "-coal"}

WT.show("mods[Bio_Industries]", mods["Bio_Industries"] )

--~ local change_oil_recipe = false
if mods["Bio_Industries"] and data.raw.item["wood-charcoal"] then
WT.dprint("\"Bio Industries\" %s has been found.", mods["Bio_Industries"])
   -- Unlock recipes for Fire extinguisher fluid
  --~ local unlocks = { WT.fire_ex_fluid .. "-coal"}
  --~ if data.raw.item["wood-charcoal"] then
  if WT.BI_adds_new_recipe then
    table.insert(unlocks, WT.fire_ex_fluid .. "-charcoal")
    WT.dprint("Will add recipe unlock for %s to effects of %s!",
      {WT.fire_ex_fluid .. "-charcoal", tech.name})
  else
    unlocks = { WT.fire_ex_fluid .. "-charcoal"}
    WT.dprint("Will replace recipe unlock for %s with unlock for %s in effects of %s!",
      {WT.fire_ex_fluid .. "-coal", WT.fire_ex_fluid .. "-charcoal", tech.name})
  end
WT.show("unlocks", unlocks)
end

-- Unlock coal and/or charcoal recipe

for u, unlock in ipairs(unlocks) do
WT.show("unlock", unlock)
--~ WT.show("data.raw.recipe[unlock]", data.raw.recipe[unlock])
  if data.raw.recipe[unlock] then
    table.insert(tech.effects, {
      type = "unlock-recipe",
      recipe = unlock
    })
    WT.dprint("Added recipe %s to unlocks of %s: %s", {unlock, tech.name, tech.effects})
  end
end

--~ WT.dprint("\"Bio Industries\" %s has been found. Adding recipe unlock for %s to effects of %s!",
            --~ {mods["Bio_Industries"], WT.fire_ex_fluid .. "-charcoal", tech.name})
