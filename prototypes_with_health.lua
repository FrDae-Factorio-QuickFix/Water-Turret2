local prototypes_with_health = {}

------------------------------------------------------------------------------------
--                                    Functions                                   --
------------------------------------------------------------------------------------
-- List of prototype types that we want to attack. This depends on reading settings
-- for immunity of spawners and turrets/worms, so we need to make this a function
-- that can be called when needed.

prototypes_with_health.attack = function(entity_type)
--~ log("Entered function attack(" .. serpent.line(entity_type) .. ")")

  if not entity_type and type(entity_type) == "string" then
    error(serpent.line(entity_type) .. " is not a valid argument! (String expected)")
  end

  local attack_entities = {
    -- We'll always want to attack these!
    ["character"] = { bool = true, order = 1},
    --~ ["spider-leg"] = { bool = true, order = 2},
    --~ ["spider-vehicle"] = { bool = true, order = 3},
    --~ ["car"] = { bool = true, order = 4},
    ["unit"] = { bool = true, order = 5},

    ["turret"] = { bool = not settings.startup["WT-immunity-turret"].value, order = 6},
    ["unit-spawner"] = { bool = not settings.startup["WT-immunity-spawner"].value, order = 7},
  }
  local ret = {}

  -- Get a complete list of enemy prototypes. Entries are arranged according
  -- to attack priority (entry with lowest value for "order" will be attacked first).
  if entity_type == "get_list" then
    for entities, values in pairs(attack_entities) do
      if values.bool then
        ret[values.order] = entities
      end
    end
--~ log("These entities may be attacked: " .. serpent.block(ret))

  -- Check if entities of a particular prototype should be attacked
  else
   ret = attack_entities[entity_type] and attack_entities[entity_type].bool
  end

  return ret
end

------------------------------------------------------------------------------------
-- Make list of healing_per_tick of the prototypes (name) that we want to attack.
-- This depends on reading settings for immunity of spawners and turrets/worms,
-- so we need to make this a function that can be called when needed.
prototypes_with_health.healing = function(entity_types)
  --~ log("Entered function healing(" .. serpent.line(entity_types) .. ")")

  local ret = {}
  local prototype_list
  for p, proto in pairs(entity_types) do
    ret[proto] = {}
--~ log("Looking for entities of type " .. serpent.line(proto))
    prototype_list = prototypes.get_entity_filtered{{ filter = "type", type = proto }}
    

    for _, protoname in pairs(prototype_list) do
--~ log("name: " .. serpent.block(protoname.name))
      ret[proto][protoname.name] = protoname.healing_per_tick or 0
    end
  end
  --~ log("End of function healing(" .. serpent.line(entity_types) .. ")")
  return ret
end


--~ ------------------------------------------------------------------------------------
--~ -- Make list of forces that are enemy of the turret force and store it with the
--~ -- turret data in the storage table.
--~ prototypes_with_health.get_enemy_forces = function(check_force)
  --~ log(string.format("Entered function get_enemy_forces(%s).", check_force))

  --~ check_force = check_force and (
                  --~ -- Force
                  --~ (check_force.valid and game.forces[check_force.name]) or
                  --~ -- Force name
                  --~ (type(check_force) == "string" and game.forces[check_force]) or
                  --~ -- Force index
                  --~ (type(check_force) == "number" and game.forces[check_force]) or
                  --~ -- Force from entity
                  --~ (check_force.valid and check_force.force)
                --~ )

  --~ if not check_force then
    --~ error(string.format("%s is not a valid force!", check_force or "nil"))
  --~ end

  --~ local ret = {}

  --~ for f, force in pairs(game.forces or {}) do
    --~ if (force ~= check_force) and
        --~ not (force.get_friend(check_force) or force.get_cease_fire(check_force)) then
      --~ ret[#ret + 1] = force.name
    --~ end
  --~ end

  --~ log(string.format("End of function get_enemy_forces(%s). (Return: %s)", check_force, serpent.block(ret)))
  --~ return ret
--~ end


------------------------------------------------------------------------------------
--                                      Lists                                     --
------------------------------------------------------------------------------------
-- List of prototype types that will be vulnerable to our damage
prototypes_with_health.vulnerable = {
  -- Everything related to electricity should take damage
  ["accumulator"] = true,
  ["boiler"] = true,
  ["burner-generator"] = true,
  ["electric-energy-interface"] = true,
  ["electric-pole"] = true,
  ["electric-turret"] = true,
  ["generator"] = true,
  ["power-switch"] = true,
}

-- List of prototype types that are entity-with-health
prototypes_with_health.immune = {
  "accumulator",
  "ammo-turret",
  "arithmetic-combinator",
  "artillery-turret",
  "artillery-wagon",
  "assembling-machine",
  "beacon",
  "boiler",
  "burner-generator",
  "car",
  "cargo-wagon",
  "character",
  "combat-robot",
  "constant-combinator",
  "construction-robot",
  "container",

  "curved-rail-a",
  "curved-rail-b",
  "decider-combinator",
  "electric-energy-interface",
  "electric-pole",
  "electric-turret",
  "fish",
  "fluid-turret",
  "fluid-wagon",
  "furnace",
  "gate",
  "generator",
  "heat-interface",
  "heat-pipe",
  "infinity-container",
  "infinity-pipe",
  "inserter",
  "lab",
  "lamp",
  "land-mine",
  "loader",
  "loader-1x1",
  "locomotive",
  "logistic-container",
  "logistic-robot",
  "market",
  "mining-drill",
  "offshore-pump",
  "pipe",
  "pipe-to-ground",
  "power-switch",
  "programmable-speaker",
  "pump",
  "radar",
  "rail-chain-signal",
  "rail-signal",
  "reactor",
  "roboport",
  "rocket-silo",
  "simple-entity",
  "simple-entity-with-force",
  "simple-entity-with-owner",
  "solar-panel",
  "spider-leg",
  "spider-vehicle",
  "splitter",
  "storage-tank",
  "straight-rail",
  "train-stop",
  "transport-belt",
  "tree",
  "turret",
  "underground-belt",
  "unit",
  "unit-spawner",
  "wall",
}
return prototypes_with_health
