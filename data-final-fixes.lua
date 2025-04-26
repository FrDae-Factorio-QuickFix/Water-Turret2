local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")
local prototypes_with_health = require('__WaterTurret-revived__/prototypes_with_health')

local acid = require('__WaterTurret-revived__/ignore_fires')

------------------------------------------------------------------------------------
--                               Utility functions                                --
------------------------------------------------------------------------------------
-- Returns true if the "damage" isn't in "tab" yet
local function can_insert(tab, damage)
  WT.dprint("Entered function can_insert(%s, %s)", { tab, damage }, "line")
  if not (tab and damage) then
    error("Missing argument! (Table: " .. tostring(not tab and "missing") ..
          ", Damage: " .. tostring(not damage and "missing"))
  end

  local insert = true
  for k, v in pairs(tab) do
    if v.type == damage then
      insert = false
      break
    end
  end

  WT.dprint("End of function can_insert(%s, %s). Return: %s", { tab, damage, insert }, "line")
  return insert
end

-- Change resistance against "damage" if it's already among the resistancies
local function replace_resistance(tab, damage)
  WT.dprint("Entered function replace_resistance(%s, %s)", { tab, damage }, "line")

  if not (tab and damage) then
    error("Missing argument! (Table: " .. tostring(not tab and "missing") ..
          ", Damage: " .. tostring(not damage and "missing"))
  end

  for k, v in pairs(tab) do
    if v.type == damage.type then
      tab[k] = damage
    end
  end

  WT.dprint("End of function replace_resistance(%s, %s)", { tab, damage }, "line")
end


------------------------------------------------------------------------------------
--                         Get default_trigger_target_mask                        --
------------------------------------------------------------------------------------
local default_target_masks =
  data.raw["utility-constants"].default.default_trigger_target_mask_by_type


------------------------------------------------------------------------------------
--      Add immunity to all entities with health that we never want to hurt.      --
--     Entities that are vulnerable to splash damage will get no resistances.     --
--       Entities that we want to attack will be marked as targets later on.      --
------------------------------------------------------------------------------------
local resistances = {
  { type = WT.steam_damage_name, decrease = 0, percent = 100 },
  { type = WT.water_damage_name, decrease = 0, percent = 100 },
  { type = WT.fire_ex_damage_name, decrease = 0, percent = 100 },
}

-- Check all prototypes of entities_with_health
WT.dprint("Setting immunities for entites_with_health.")

for _, prototypes in ipairs(prototypes_with_health.immune) do
  -- Don't give immunity to entities that should take damage!
  if not (prototypes_with_health.vulnerable[prototypes] or
            --~ prototypes_with_health.attack[prototypes]) then
            prototypes_with_health.attack(prototypes)) then


   --if data.raw[prototypes] then     

    for p, prototype in pairs(data.raw[prototypes]) do
WT.dprint("Type: %s\tPrototype: %s", { prototypes, prototype.name })
      -- Ignore dummies
      if not (WT.dummy_types[prototype] and prototypes == WT.dummy_type) then
        prototype["resistances"] = prototype["resistances"] or {}
        for r, resistance in ipairs(resistances) do
          -- Add resistance if entity has no resistance against this damage yet!
          if can_insert(prototype["resistances"], resistance.type) then
            table.insert(prototype.resistances, resistance)
          -- Replace resistance if prototype already is resistant to this damage type!
          else
            replace_resistance(prototype.resistances, resistance)
          end
        end

      --end
--~ WT.show("Resistances", prototype.resistances)
    end
  end
  end


end


------------------------------------------------------------------------------------
--  Allow attacking mobile targets (this may include spawners and worms/turrets)  --
------------------------------------------------------------------------------------
--~ resistances = {
  --~ WT.steam_damage_name,
  --~ WT.water_damage_name,
  --~-- WT.fire_ex_damage_name,
--~ }
--~ local vulnerability, decrease
WT.dprint("Allow attacking mobile targets")


for e, entitytype in pairs(prototypes_with_health.attack("get_list")) do
WT.dprint("entitytype: %s\te: %s", { entitytype, e })
  -- Mark prototype class as target
  default_target_masks[entitytype] = default_target_masks[entitytype] or { "common" }
  table.insert(default_target_masks[entitytype], WT.trigger_target_mobile)

  --~ -- Make individual prototypes vulnerable: The turrets do only small damage per
  --~ -- tick, and if the target's healing_per_tick is higher than the damage, turrets
  --~ -- won't have a chance to ever defeat it. So let's cancel out healing_per_tick!
  --~ for p, prototype in pairs(data.raw[entitytype]) do
--~ WT.dprint("prototype: %s\tp: %s", { prototype.name, p })
    --~ for r, resistance in ipairs(resistances) do
      --~ -- Define a negative resistance
      --~ decrease = prototype.healing_per_tick
--~ WT.show("decrease", decrease)
      --~ decrease = decrease and (
                                --~ (decrease > 0 and decrease * -1) or
                                --~ (decrease < 0 and decrease) or
                                --~ 0
                              --~ ) or 0
      --~ if decrease < 0 then
        --~ decrease = decrease - 0.5
      --~ end

      --~ vulnerability = {
        --~ type = resistance,
        --~ decrease = decrease,
        --~ percent = 0
      --~ }
--~ WT.show("vulnerability", vulnerability)
      --~ -- Add resistance if entity has no resistance against this damage yet!
      --~ prototype.resistances = prototype.resistances or {}
      --~ if decrease and decrease ~= 0 then
        --~ if can_insert(prototype.resistances, vulnerability.type) then
          --~ table.insert(prototype.resistances, vulnerability)
  --~ WT.dprint("Added vulnerability to %s!", prototype.name)
        --~ -- Replace resistance if prototype already is resistant to this damage type!
        --~ else
          --~ replace_resistance(prototype.resistances, vulnerability)
  --~ WT.dprint("Changed resistance to %s for %s!", { vulnerability, prototype.name })
        --~ end
      --~ end
    --~ end
    --~ WT.dprint("Prototype %s:\tResistances: %s", { prototype.name, prototype.resistances })
  --~ end
end


------------------------------------------------------------------------------------
--                         Set resistances for fire dummy                         --
------------------------------------------------------------------------------------
WT.dprint("Setting resistances for fire dummies")

resistances = {}
-- Make this a table so we're ready if we ever need to exclude more damage types
-- from the immunity list
local vulnerable = {
  --~ [WT.water_damage_name] = {decrease = -0.5, percent = 0},
  --~ [WT.fire_ex_damage_name] = {decrease = -0.5, percent = 0},
  [WT.water_damage_name] = true,
  [WT.fire_ex_damage_name] = true,
}

WT.show("Damage types known to the game", data.raw["damage-type"])
-- Look for every damage type known to the game to list of resistances
local percent
for d, damage in pairs(data.raw["damage-type"]) do
WT.dprint("d: %s\tdamage: %s", {d, damage})
  percent = 0
  -- Add damage type unless we want the entity to be vulnerable to it
  if not vulnerable[damage.name] then
    percent = 100
  end
  resistances[#resistances + 1] = {
    type = damage.name,
    decrease = 0,
    percent = percent
  }
end
--~ WT.show("Resistances of \"fire-dummy\"", resistances)
data.raw[WT.dummy_type][WT.fire_dummy_name].resistances = resistances

WT.show("Final fire dummy", data.raw[WT.dummy_type][WT.fire_dummy_name])


------------------------------------------------------------------------------------
--                         Set resistances for acid dummy                         --
------------------------------------------------------------------------------------
if data.raw[WT.dummy_type][WT.acid_dummy_name] then
  for r, resistance in pairs(resistances) do
    if resistance.type == WT.steam_damage_name then
      --~ resistance.decrease = -0.5
      resistance.percent = 0
    end
  end
  WT.show("Resistances for acid dummy", resistances)
  data.raw[WT.dummy_type][WT.acid_dummy_name].resistances = resistances
  WT.show("Final acid dummy",  data.raw[WT.dummy_type][WT.acid_dummy_name])
end

------------------------------------------------------------------------------------
--                         Define targets for our turrets                         --
------------------------------------------------------------------------------------

-- Attack these targets
WT.dprint("Define attack targets for turrets")

local turrets = data.raw[WT.turret_type]
turrets[WT.steam_turret_name].attack_target_mask = {
  WT.trigger_target_mobile,
  WT.trigger_target_acid_dummy,
}
turrets[WT.water_turret_name].attack_target_mask = {
  WT.trigger_target_mobile,
  WT.trigger_target_fire_dummy,
  WT.trigger_target_acid_dummy,
}
turrets[WT.extinguisher_turret_name].attack_target_mask = {
  WT.trigger_target_fire_dummy,
  WT.trigger_target_acid_dummy,
}
turrets[WT.extinguisher_turret_water_name].attack_target_mask = {
  WT.trigger_target_fire_dummy,
  WT.trigger_target_acid_dummy,
}

-- Ignore these targets
turrets[WT.steam_turret_name].ignore_target_mask = {WT.trigger_target_ignore}
turrets[WT.water_turret_name].ignore_target_mask = {WT.trigger_target_ignore}
turrets[WT.extinguisher_turret_name].ignore_target_mask = {WT.trigger_target_ignore}
turrets[WT.extinguisher_turret_water_name].ignore_target_mask = {WT.trigger_target_ignore}

for turret, _ in pairs(WT.turret_names) do
  WT.dprint("%s ignore_target_mask: ",
            { turret, data.raw[WT.turret_type][turret].ignore_target_mask })
end

-- Target masks of other turrets
WT.dprint("Setting target masks of other turrets")

for _, name in pairs({
      "artillery-turret", "turret",
      "ammo-turret", "electric-turret", "fluid-turret" }) do
  for t, turret in pairs(data.raw[name]) do
  -- Add our dummies to ignore_target_masks of other turrets
    if not (turret.type == WT.turret_type and WT.turret_names[turret.name]) then
      turret.ignore_target_mask = turret.ignore_target_mask or {}
      table.insert(turret.ignore_target_mask, WT.trigger_target_fire_dummy)
      table.insert(turret.ignore_target_mask, WT.trigger_target_acid_dummy)
WT.dprint("Turret: %s\tIgnore targets: %s", { turret.name, turret.ignore_target_mask or {} })

  -- Remove our dummies from attack_target_masks of other turrets
      turret.attack_target_mask = turret.attack_target_mask or { "common", "ground-unit"}
      for ta, target in pairs(turret.attack_target_mask or {}) do
        if target == WT.trigger_target_fire_dummy or
            target == WT.trigger_target_acid_dummy then
          turret.attack_target_mask[ta] = nil
        end
      end
    end
WT.dprint("Turret: %s\tAttack targets: %s", { turret.name, turret.attack_target_mask or {} })
  end
end


------------------------------------------------------------------------------------
-- Let dummies be placed when a fire is created
------------------------------------------------------------------------------------
local acids = acid.get_acid()
local ignore = acid.get_ignorelist()
local fires = data.raw.fire

WT.show("Clean acid splashes", settings.startup["WT-turrets_clean_acid"].value)
WT.show("acids", acids)
WT.show("ignore", ignore)

for name, entity in pairs(fires) do
  if not ignore[entity.name] and name ~= WT.fake_fire_name then
    WT.show("Adding created_effect to", entity.name)

    entity.created_effect = {
      type = "direct",
      action_delivery = {
        type = "instant",
        target_effects = {
          type = "create-entity",
          entity_name = acids[name] and WT.acid_dummy_name or WT.fire_dummy_name,
          --~ -- ignore_collision_condition = true,
          trigger_created_entity = true,
          offset_deviation = {{0, 0}, {0, 0}},
          offsets ={ {0, 0} }
        }
      },
    }
  else
    WT.show("Ignore", entity.name)
  end
WT.show("entity.flags", entity.flags)
  --~ entity.selectable_in_game = true
  entity.selectable_in_game = WT.debug_in_log
  WT.dprint("created_effect for %s: %s", {name, entity.created_effect or "no effect"})
end



------------------------------------------------------------------------------------
--                     Tint barrel icons for item and recipes                     --
------------------------------------------------------------------------------------
local top_and_hoop_color = {
        a = 0.75,
        b = 0.0,
        g = 0.0,
        r = 0.9
  }
local barrel = data.raw.item[WT.fire_ex_fluid .. "-barrel"]
if barrel and barrel.icons then
  if barrel.icons[1] then
  data.raw.item[WT.fire_ex_fluid .. "-barrel"].icons[1].tint = top_and_hoop_color
  end
  if barrel.icons[3] then
  data.raw.item[WT.fire_ex_fluid .. "-barrel"].icons[3].tint = top_and_hoop_color
  end
WT.dprint("Changed barrel icon for %s!", {barrel.name})
end


for n, name in ipairs({"", "empty-"}) do
  local barrel = data.raw.recipe[name .. WT.fire_ex_fluid .. "-barrel"]

  if barrel and barrel.icons then
    if barrel.icons[1] then
      barrel.icons[1].tint = top_and_hoop_color
    end
    if barrel.icons[3] then
        barrel.icons[3].tint = top_and_hoop_color
    end
  end

--WT.dprint("Changed barrel icon for recipe %s.", barrel.name )

end


------------------------------------------------------------------------------------
--                          Compatibility with other mods                         --
------------------------------------------------------------------------------------

-- "Amator Phasma's Coal & Steam"
require('mod_compatibility.apm_power')

-- "Bio Industries"
require('mod_compatibility.bio_industries')

-- "Hardened pipes"
require('mod_compatibility.hardened_pipes')

-- "Fire Department QuickFix"
require('mod_compatibility.fire_department_fix')

-- "Universal Turret_fix"
require('mod_compatibility.uniturret_fix')

-- "Will-o-the-wisps" (and forks)
require('mod_compatibility.will-o-the-wisps')



---TESTING
local turrets = data.raw[WT.turret_type]
for t, turret in pairs({WT.water_turret_name, WT.steam_turret_name, WT.extinguisher_turret_name, WT.extinguisher_turret_water_name} ) do
WT.show(turret .." resistances", turrets[turret].resistances)
end



local allturrets = data.raw["turret"]
for name, dat in pairs(allturrets) do
  if name ~= WT.water_turret_name and name ~= WT.steam_turret_name and name ~= WT.extinguisher_turret_name and name ~= WT.extinguisher_turret_water_name then
    local im = {}
    for _, d in pairs(dat.ignore_target_mask) do
      im[d] = true
    end
    if not im[WT.trigger_target_mobile] then
      table.insert(dat.ignore_target_mask, WT.trigger_target_mobile)
    end
    if not im[WT.trigger_target_acid_dummy] then
      table.insert(dat.ignore_target_mask, WT.trigger_target_acid_dummy)
    end
    if not im[WT.trigger_target_fire_dummy] then
      table.insert(dat.ignore_target_mask, WT.trigger_target_fire_dummy)
    end
    if not im[WT.trigger_target_ignore] then
      table.insert(dat.ignore_target_mask, WT.trigger_target_ignore)
    end

  end
  
end

data.raw.fluid[WT.fire_ex_fluid].base_color = WT.fire_ex_fluid_tint