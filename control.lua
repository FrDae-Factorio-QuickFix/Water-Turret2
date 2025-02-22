log("Entered control.lua")

local WT = require("common")()
local swap_turrets = require("swap_turrets")
local math2d = require("math2d")
local ignore_or_acid = require("ignore_fires")

-- Make remote interface for "Lua API global Variable Viewer (gvv)" by x2605.
-- (https://mods.factorio.com/mod/gvv)
-- If that mod is active, one can inspect the global table of this mod at runtime.

WT.show("script.active_mods['gvv']", script.active_mods["gvv"])
WT.show("WT.debug_gvv", WT.debug_gvv)
if script.active_mods["gvv"] and WT.debug_gvv then
  require("__gvv__.gvv")()
  WT.dprint({"WT-misc.WT-gvv_enabled", script.mod_name, {"mod_name.gvv"}})
end

local on_tick_profiler, turret_profiler

--~ ------------------------------------------------------------------------------------
--~ -- Check if target belongs to us (own force, friends, allies) or is an enemy
--~ -- (returns true or false)
--~ ------------------------------------------------------------------------------------
--~ local function is_enemy(turret, target)
  --~ WT.dprint("Entered function is_enemy(%s, %s).", {
    --~ WT.print_name(turret), WT.print_name(target)
  --~ })

  --~ local ret

  --~ -- Check arguments
  --~ if not (turret and turret.valid) then
    --~ error(string.format("%s is not a valid turret!", WT.print_name_id(turret)))
  --~ end


  --~ if target and target.valid and target.force then
    --~ ret = WT.is_enemy_force(turret.force, target.force)
  --~ end

  --~ WT.dprint("End of function is_enemy(%s, %s). Return: %s", {
    --~ WT.print_name(turret), WT.print_name(target), ret
  --~ })
  --~ return ret
--~ end



------------------------------------------------------------------------------------
-- Check whether fire dummy actually marks fires. (Returns boolean value)
------------------------------------------------------------------------------------
local function dummy_marks_fire(dummy)
  WT.dprint("Entered function dummy_marks_fire(%s) on tick %g.", {
            WT.print_name_id(dummy), game.tick
  })

  local ret = false

  -- Check argument
  if dummy and dummy.valid then
WT.dprint("Dummy is valid!")


    local dummy_id = dummy.unit_number

    local fire_id = global.fire_dummies[dummy_id] and global.fire_dummies[dummy_id].fire_id

    local fire = fire_id and global.fires[fire_id] and
                    global.fires[fire_id].fire_entity and
                    global.fires[fire_id].fire_entity.valid

    if global.fire_dummies[dummy_id] and fire then
      ret = true
    end
  end

  WT.dprint("End of function dummy_marks_fire(%s) on tick %g. (Return: %s)", {
            WT.print_name_id(dummy), game.tick, ret
  })
  return ret
end


------------------------------------------------------------------------------------
--                  Search for fire
------------------------------------------------------------------------------------
local function find_fire(turret)
  WT.dprint("Entered function find_fire(%s) on tick %g.",
                { WT.print_name_id(turret), game.tick })

  -- Check argument
  if not (turret and turret.valid and global.WT_turrets[turret.unit_number]) then
    error("Wrong arguments for function find_fire(turret):\nTurret is not valid!\n")
  end

  local ret

  -- Determine search area in the direction the turret is facing
  local area = global.WT_turrets[turret.unit_number].area or
                WT.get_turret_area(turret)
WT.show("Turret area", area)
  local x_min = area.left_top.x or area.left_top[1]
  local y_min = area.left_top.y or area.left_top[2]
  local x_max = area.right_bottom.x or area.right_bottom[1]
  local y_max = area.right_bottom.y or area.right_bottom[2]
WT.show("global.dummy_positions", global.dummy_positions)
  for x, y in pairs(global.dummy_positions) do
WT.dprint("x: %s\tx_min: %s\tx_max: %s", {x, x_min, x_max})
    if x >= x_min and x <= x_max then
WT.dprint("x is valid -- checking y!")
      for y, dummy_id in pairs(y) do
WT.dprint("y: %s\ty_min: %s\ty_max: %s", {y, y_min, y_max})
        if y >= y_min and y <= y_max and WT.can_shoot(turret, {x, y}) then
          ret = dummy_id
          break
        end
      end
    end
    if ret then
      break
    end
  end

  WT.dprint("End of function find_fire(%s) on tick %g. (Return: %s)", {
    WT.print_name_id(turret),
    game.tick, ret or "nil"
  })
  return ret
end


------------------------------------------------------------------------------------
-- Search for enemies within the turret's range (returns nil or table of entities).
-- Expects: turret (entity)
------------------------------------------------------------------------------------
local function find_enemies(turret)
  WT.dprint("Entered function find_enemies(%s) on tick %g.", {
    WT.print_name_id(turret), game.tick
  })

  -- Check arguments
  if not (turret and turret.valid) then
    error(serpent.line(turret) .. " is not a valid argument!")
  end

  if not global.WT_turrets[turret.unit_number] then
    WT.dprint("Turret is not in list!")
    return
  end

  local ret

  -- Determine search area in the direction the turret is facing
  local area = global.WT_turrets[turret.unit_number].area or WT.get_turret_area(turret)

  -- Find entities that are potential enemies
  WT.show("global.enemy_types", global.enemy_types)
  WT.show("area", area)
  WT.dprint("WT.force_relations[%s]: %s", {turret.force.name, WT.force_relations[turret.force.name]})

  local enemies = turret.surface.find_entities_filtered({
    type = global.enemy_types,
    --~ position = turret.position,
    --~ radius = global.WT_turrets[turret.unit_number].range
    area = area,
    force = WT.force_relations[turret.force.name],
  })
  WT.show("Enemies in area", enemies)

  -- Remove entities that are not enemies of the turret
  local cnt = 0
  for e, enemy in pairs(enemies) do
    --~ WT.dprint("index: %g\tenemy: %s", { e, enemy })
    --~ if not (
      --~ is_enemy(turret, enemy) and
      --~ math2d.bounding_box.contains_point(area, enemy.position) and
      --~ WT.is_in_range(turret, enemy)
    if not (WT.is_enemy(turret, enemy) and WT.can_shoot(turret, enemy.position)) then
      enemies[e] = nil
      cnt = cnt + 1
    end
  end
  WT.dprint("Enemy list after removing %g enemies: %s", {cnt, enemies})

  -- We want to find enemies in the order of enemy types stored in the global table
  for p, prototype in ipairs(global.enemy_types) do
    for e, enemy in pairs(enemies or {}) do
WT.dprint("p: %s\tprototype: %s\te: %s\tenemy: %s", {p, prototype, e, WT.print_name_id(enemy)})
      if enemy.type == prototype then
        ret = enemy
        break
      end
    end
    if ret then
      break
    end
  end


  WT.dprint("End of function find_enemies(%s) on tick %g (Found %s)", {
    WT.print_name_id(turret), game.tick, (ret and WT.print_name_id(ret) or "no")
  })
  return ret
end


------------------------------------------------------------------------------------
-- Remove entry from lists
------------------------------------------------------------------------------------
local function remove_fire_and_dummy(entity_type, id)
WT.dprint("Entered function remove_fire_and_dummy(%s, %g).", { entity_type, id })

  if not (entity_type and type(entity_type) == "string" ) then
    error("Wrong entity (string expected): " .. serpent.line(entity_type))
  elseif not (id and type(id) == "number") then
    error("Wrong ID (number expected): " .. serpent.line(id))
  end

  if entity_type ~= "fire" and entity_type ~= "dummy" then
    WT.dprint("Nothing to do for entity %s!", { entity_type })
    return
  end

  ------------------------------------------------------------------------------------
  local fire, dummy, f_index, d_index

  -- Get entities
  if entity_type == "fire" and global.fires[id] then
WT.dprint("Looking for fire %s", { id })
    f_index     = id
    fire        = global.fires[f_index].fire_entity

    d_index     = f_index and global.fires[f_index].dummy_id
    dummy       = d_index and global.fire_dummies and
                  global.fire_dummies[d_index] and
                  global.fire_dummies[d_index].dummy_entity

  elseif entity_type == "dummy" and global.fire_dummies[id] then
WT.dprint("Looking for dummy %s", { id })
    d_index     = id
    dummy       = global.fire_dummies[d_index].dummy_entity

    f_index     = d_index and global.fire_dummies[d_index].fire_id
    fire        = f_index and global.fires and
                  global.fires[f_index] and
                  global.fires[f_index].fire_entity
  end
WT.dprint("fire[%s]:\t%s", {
  f_index, (fire and fire.valid and fire.name or "NIL")
})


  -- Remove from global tables
  local function remove(x, y)
    if global.dummy_positions[x] then
      global.dummy_positions[x][y] = nil
    end
    if global.dummy_positions[x] and not next(global.dummy_positions[x]) then
      global.dummy_positions[x] = nil
    end
  end

  local x, y

  if f_index then
    if fire and fire.valid then
      x = fire.position.x or fire.position[1]
      y = fire.position.y or fire.position[2]
      remove(x, y)
    end
    global.fires[f_index] = nil
WT.dprint("Removed fire " .. f_index .. " from global.fires!")
  end

  if d_index then
    if dummy and dummy.valid then
      x = dummy.position.x or dummy.position[1]
      y = dummy.position.y or dummy.position[2]
      remove(x, y)
    end
    global.fire_dummies[d_index] = nil
WT.dprint("Removed dummy " .. d_index .. " from global.fire_dummies!")
  end

  -- Destroy entities
  if fire and fire.valid then
    fire.surface.create_entity{position = fire.position, name = WT.burnt_patch }
    fire.destroy()
WT.show("DESTROYED FIRE", f_index)
  end

  if dummy and dummy.valid then
    dummy.surface.create_entity{position = dummy.position, name = WT.burnt_patch }
    dummy.destroy()
WT.show("DESTROYED DUMMY", d_index)
  end

--~ WT.dprint("global: " .. serpent.block(global))
WT.dprint("f_index: " .. tostring(f_index) .. "\td_index: " .. tostring(d_index))


  WT.dprint("End of function remove_fire_and_dummy(%s, %g).", { entity_type, id })
  return
end


------------------------------------------------------------------------------------
--                             Target enemies or fire                             --
------------------------------------------------------------------------------------
local function target_enemy_or_fire(turret)
  WT.dprint("Entered function target_enemy_or_fire(%s) on tick %s.", { turret, game.tick })
--~ WT.show("Number of turrets", table_size(global.WT_turrets))

  -- Check argument
  --~ if type(turret) == "number" then
    --~ turret = global.WT_turrets[turret] and global.WT_turrets[turret].entity
  turret = (type(turret) == "number" and global.WT_turrets[turret]
                            and global.WT_turrets[turret].entity) or
            (turret and turret.valid and
              global.WT_turrets[turret.unit_number] and
              global.WT_turrets[turret.unit_number].entity)

  --~ if type(turret) == "number" then
    --~ turret = global.WT_turrets[turret] and global.WT_turrets[turret].entity

  --~ elseif (not WT.is_WT_turret(turret)) or turret.name == WT.steam_turret_name then
  --~ elseif not WT.is_WT_turret_name(turret, WT.water_turret_name) then
  --~ elseif not turret and WT.is_WT_turret_name(turret, WT.water_turret_name) then
    --~ WT.show("Not a valid turret", print_name_id(turret))
    --~ return
  --~ end
--~ WT.show("turret", WT.print_name_id(turret))
--~ WT.show("Number of turrets", table_size(global.WT_turrets))

  ------------------------------------------------------------------------------------
  -- Leave early?
  ------------------------------------------------------------------------------------

  -- Return if there is no turret
  if not turret then
    return
  end

  -- No need to do anything if turret has no ammo!
  local ammo = turret.get_fluid_contents()
  if table_size(ammo) == 0  then
    WT.dprint("Leaving early: No ammo!")
    return
  end


  ------------------------------------------------------------------------------------
  -- Check if turret is busy already
  ------------------------------------------------------------------------------------
  WT.dprint("Check if %s is attacking something.", { WT.print_name_id(turret) })

  local target = turret.shooting_target

WT.show("Current target", WT.print_name_id(target))
  -- Turret attacks something.
  if target and target.valid then
    WT.dprint("%s: shooting at %s.", { WT.print_name_id(turret), WT.print_name_id(target) })

    -- Fire dummy was attacked -- remove dummy if it marks no fire!
    if WT.is_WT_dummy(target) and not dummy_marks_fire(target) then
        WT.dprint("No fires at position of %s.", { WT.print_name_id(target) })
        remove_fire_and_dummy("dummy", target.unit_number)
        target.destroy()
    end
  end

  -- Prioritize targets according to startup setting
WT.dprint("Prioritizing attack!")
  -- Attack fire!
WT.show("Priority setting", WT.waterturret_priority)

WT.show("not target", (not target))
WT.show("WT.is_WT_dummy(target)", WT.is_WT_dummy(target))
  if WT.waterturret_priority == "fire" then
WT.show("Looking for fire", global.WT_turrets[turret.unit_number])
    if not (target and WT.is_WT_dummy(target)) then
WT.dprint("Need to find fire")
      --~ local fire = WT.find_fire(turret)
      local fire = find_fire(turret)
WT.show("Found fire", fire)
      fire = fire and global.fire_dummies[fire] and global.fire_dummies[fire].dummy_entity
      if fire and fire.valid then
        turret.shooting_target = fire
      end
    end
  -- Attack enemies!
  elseif WT.waterturret_priority == "enemy" then
WT.show("Looking for enemies", { WT.print_name_id(turret) })
    if (not target) or WT.is_WT_dummy(target) then
      local target = find_enemies(turret)
      if target and target.valid then
        WT.show("Attacking enemy", WT.print_name_id(target))
        turret.shooting_target = target
        return
      end
    end
  -- Player doesn't care about priority, the game decides which entity to attack!
  else
    WT.dprint("Nothing to do -- automatic targetting is on!")
  end

  WT.dprint("End of function target_enemy_or_fire(%s) on tick %s.", {
    WT.print_name_id(turret), game.tick
  })
end
------------------------------------------------------------------------------------
--                               Act on turret tick                               --
------------------------------------------------------------------------------------
local function check_turret(id)
  local turret = id and global.WT_turrets[id]


WT.show("Turret data", turret and WT.print_name_id(turret.entity or "nil"))
WT.show("turret.tick", turret and turret.tick)
WT.show("action_delay", WT.action_delay)

  local turret_id = id

  -- Remove invalid turrets from list
  if not (turret and WT.is_WT_turret(turret.entity)) then
    global.WT_turrets[id] = nil
    --~ remove_turret(id)
    WT.dprint("Removed turret %s from list because it was not valid.", { id })

  -- Check the turret!
  else
WT.dprint("May act on turret")
    local next_tick = turret.tick + WT.action_delay
--~ WT.dprint("%s is not an extinguisher turret: %s", {turret.entity.name, turret.entity.name ~= WT.extinguisher_turret_name})
    -- Swap turrets if necessary
    --~ local turret_id = (turret.entity.name ~= WT.extinguisher_turret_name) and
                       --~ (turret.entity.name ~= WT.extinguisher_turret_water_name) and swap_turrets.swap_turrets(id) or id
    --~ turret_id = swap_turrets.swap_turrets(id) or id
    turret_id = swap_turrets.swap_turrets(id)
WT.dprint("Returned from swap_turrets. Old ID: %s\tNew ID: %s turret_id", {id, turret_id})
    --~ if turret_id and global.WT_turrets[turret_id].entity.valid then
    --~ if WT.is_WT_turret(turret_id) then

      -- Remove old turret from list
      if turret_id ~= id then
        global.WT_turrets[id] = nil
      end

      -- Set next action tick
      --~ local next_tick = game.tick + WT.action_delay
      --~ global.WT_turrets[turret_id].tick = game.tick + WT.action_delay
      global.WT_turrets[turret_id].tick = next_tick
      global.turret_ticks[next_tick] = global.turret_ticks[next_tick] or {}
      global.turret_ticks[next_tick][turret_id] = true


      -- Check if we need to find fires or retarget
      if WT.waterturret_priority ~= "default" and
        WT.is_WT_turret_name(global.WT_turrets[turret_id].entity,
                              WT.water_turret_name) then
        WT.dprint("Water turret -- going to target_enemy_or_fire!")
        target_enemy_or_fire(turret_id)
      end

    --~ -- This should never be reached!
    --~ else
      --~ error("Something went wrong! Turret with id ".. tostring(turret_id) ..
            --~ "doesn't exist!\n" .. serpent.block(global.WT_turrets))
    --~ end
  end
  return turret_id
end



















------------------------------------------------------------------------------------
--                                 Event handlers                                 --
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Do this on every tick
local function on_tick(event)
WT.dprint("Entered function on_tick on tick %s", {event.tick})
  --~ global.enemy_types = global.enemy_types or WT.enemies("get_list")
  --~ global.acids = global.acids or WT.make_name_list(ignore_or_acid.get_acid())
  --~ global.ignore_fires = global.ignore_fires or ignore_or_acid.get_ignorelist()

  global.turret_ticks = global.turret_ticks or {}

  local tick = event.tick
  local next_tick = tick + WT.action_delay
WT.show("event tick", tick)
WT.show("next_tick", next_tick)


  local turrets = global.turret_ticks[tick]
WT.show("turrets", turrets)
  if turrets and next(turrets) then
--~ log("Active turrets on tick " .. tick .. ": " .. table_size(turrets))
    local new_id
    global.turret_ticks[next_tick] = global.turret_ticks[next_tick] or {}

    --~ WT.dprint("%s turrets are active this tick: %s", {table_size(turrets), turrets})
    WT.dprint("%s turrets are active this tick.", {table_size(turrets)})
    for turret, _ in pairs(turrets) do
      WT.dprint("Checking turret %s", {turret})
      new_id = check_turret(turret)

      global.turret_ticks[next_tick][new_id] = true
    end
    --~ global.turret_ticks[tick] = nil
--~ WT.dprint("Removed tick %s from list: %s", {tick, global.turret_ticks})
  else
WT.dprint("Nothing to do on tick %s", {tick})
  end

  global.turret_ticks[tick] = nil
--~ WT.dprint("Removed tick %s from list: %s", {tick, global.turret_ticks})
WT.dprint("Removed tick %s from list.", {tick})

WT.dprint("End of function on_tick on tick %s", {event.tick})
end


------------------------------------------------------------------------------------
-- Extinguish_fire
local function extinguish_fire(entity)
  WT.dprint("Entered function extinguish_fire(%s).", { WT.print_name_id(entity) })

  local id = (entity and type(entity) == "number" and entity) or entity.unit_number
  local dummy = id and global.fire_dummies[id] and global.fire_dummies[id].dummy_entity

  if dummy then
    local fires = dummy.surface.find_entities_filtered{
      type = "fire",
      position = dummy.position,
      radius = WT.fire_dummy_radius,
    }

    if fires then
      for f, fire in pairs(fires) do
        if (not global.ignore_fires[fire.name]) then
          -- Don't need to raise the event because register_on_entity_destroyed is used!
          fire.destroy()
        end
      end
    end
  WT.dprint("Extinguished %g fires around position %s.", { table_size(fires), entity.position })
  end

  WT.dprint("End of function extinguish_fire(%s).", { WT.print_name_id(entity) })
end


------------------------------------------------------------------------------------
-- Remove fire dummies without fire from surfaces
local function remove_fire_dummies_from_surface(event)
  WT.dprint("Entered function remove_fire_dummies_from_surface (tick %g).", { event and event.tick })

  local dummies = {}
  for s, surface in pairs(game.surfaces) do
    dummies = surface.find_entities_filtered({
      name = WT.fire_dummy_name,
      type = WT.dummy_type
    })
WT.dprint("Found %g dummies on surface \"%s\".", {#dummies, s})

    -- Destroy all dummies that are not in our global lists!
    for d, dummy in pairs(dummies) do
      if not global.fire_dummies[dummy.unit_number] then
WT.dprint("%s is not in global dummy list!", { WT.print_name_id(dummy) })
        dummy.destroy()
WT.dprint("Removed %s!", { WT.print_name_id(dummy) })
      end
    end
WT.dprint("Done!")
  end

  WT.dprint("End of function remove_fire_dummies_from_surface (tick %g).", { event and event.tick })
  return
end


------------------------------------------------------------------------------------
-- Remove fire dummies without fire from tables
local function remove_fire_dummies_from_table(event)
  WT.dprint("Entered function remove_fire_dummies_from_table (tick %g).",
            { event and event.tick })

  local dummies = {}
  local cnt

WT.dprint("Found %g dummies in global.fire_dummies.", { table_size(global.fire_dummies) })

  -- Destroy all dummies in our global list that don't mark fires!
  for d, dummy in pairs(global.fire_dummies) do
    if not dummy_marks_fire(dummy) then
WT.dprint("%s is in our table but doesn't mark fire.", { WT.print_name_id(dummy) })
      remove_fire_and_dummy("dummy", dummy.dummy_id)
WT.dprint("Removed %s!", { WT.print_name_id(dummy) })
    end
  end

  WT.dprint("End of function remove_fire_dummies_from_table (tick %g).",
            { event and event.tick })
  return
end


------------------------------------------------------------------------------------
-- on_built
local function on_built(event)
  WT.dprint("Entered function on_built(%s).", { WT.print_name_id(event.created_entity) })

  local entity = event.created_entity or event.entity
--~ local turret_data

  if entity and entity.valid then
    -- Turret was built
    if entity.type == WT.turret_type and WT.turret_names[entity.name] then
      global.WT_turrets[entity.unit_number] = {}
      local area = (entity.name ~= WT.extinguisher_turret_name) and
                    WT.get_turret_area(entity) or nil
      -- range may already be set in WT.get_turret_area()!
      local range = global.WT_turrets[entity.unit_number].range

      WT.force_relations[entity.force.name] = WT.force_relations[entity.force] or
                                          WT.get_enemy_forces(entity.force)
--~ WT.show("entity.force", entity.force.name)
WT.dprint("WT.force_relations[%s]: %s", {entity.force.name, WT.force_relations[entity.force.name]})
      local next_tick = event.tick
      local id = entity.unit_number

      global.WT_turrets[id] = {
        entity = entity,
        -- We want to check the new turret as soon as possible!
        tick = next_tick,
        -- Set the rectangular area (2*range x range) in the direction the
        -- turret is facing. It will be used when finding enemies or fires.
        -- (Recalculate when turret is rotated or moved.)
        area = area,
        id = id,
        min_range = entity.prototype.attack_parameters.min_range,
        range = range or entity.prototype.attack_parameters.range,
        enemy_forces = WT.force_relations[entity.force.name],
      }
      global.turret_ticks[next_tick] = global.turret_ticks[next_tick] or {}
      global.turret_ticks[next_tick][id] = true

WT.dprint("global.WT_turrets[%s]: %s", {entity.unit_number, global.WT_turrets[entity.unit_number]})
    end
  end

  WT.dprint("End of function on_built(%s).", { WT.print_name_id(event.created_entity) })
end


------------------------------------------------------------------------------------
-- on_remove
local function remove_turret(turret_id)
  WT.dprint("Entered function remove_turret(%s)", {turret_id})

  local turret = turret_id and global.WT_turrets[turret_id]

    --~ global.WT_turrets[entity.unit_number] = nil
    if turret then

  WT.show("Removing", WT.print_name_id(turret.entity))
      global.turret_ticks[turret.tick][turret_id] = nil
      if not next(global.turret_ticks[turret.tick]) then
        global.turret_ticks[turret.tick] = nil
      end
      global.WT_turrets[turret_id] = nil

    end
  WT.dprint("End of function remove_turret(%s)", { WT.print_name_id(turret) })
end


------------------------------------------------------------------------------------
-- on_player_rotated_entity
local function on_player_rotated_entity(event)
  WT.dprint("Entered function on_player_rotated_entity(%s).", { WT.print_name_id(event.entity) })

  local entity = event.entity

  if WT.is_WT_turret(entity) and not WT.is_WT_turret_name(WT.extinguisher_turret_name) then
    WT.dprint("%s has been moved: recalculating area!", { WT.print_name(entity) })
    global.WT_turrets[entity.unit_number].area = WT.get_turret_area(entity)
  end

  WT.dprint("End of function on_player_rotated_entity(%s).", { WT.print_name_id(event.entity) })
end


------------------------------------------------------------------------------------
-- Picker Dollies: on_moved
local function on_moved(event)
  WT.dprint("Entered function on_moved(%s).", { WT.print_name_id(event.moved_entity) })

  local entity = event.moved_entity

  if WT.is_WT_turret(entity) then
    WT.dprint("%s has been moved: recalculating area!", { WT.print_name(entity) })
    global.WT_turrets[entity.unit_number].area = WT.get_turret_area(entity)
  end

  WT.dprint("End of function on_moved(%s).", { WT.print_name_id(event.moved_entity) })
end


------------------------------------------------------------------------------------
-- Remove slow-down effect for friendly entities
local function remove_slowdown_sticker(event)
  WT.dprint("Entered event script for events.on_trigger_created_entity(%s).", { event }, "line")
  local sticker = event.entity
  local turret = event.source

  --~ WT.show("sticker", WT.print_name_id(sticker))
  --~ WT.show("turret", WT.print_name_id(turret))

  if sticker and sticker.name == WT.slowdown_sticker_name and
      turret and WT.is_WT_turret(turret) then

    local affected = sticker.sticked_to
    local turret_force = turret.force and turret.force.name
  --~ WT.show("Sticker is attached to", affected and affected.name)
  --~ WT.show("Stickers that affect the entity", affected and affected.stickers)
  --~ WT.show("Force of affected entity", affected and affected.force and affected.force.name)
  --~ WT.show("Force of turret", turret and turret.force and turret.force.name)
    if affected and affected.force and affected.force.name == turret_force then
      WT.dprint("%s affected %s with %s -- removing sticker!", {
        WT.print_name_id(turret), WT.print_name_id(affected), sticker.name
      })
      sticker.destroy()
    end
  end

  WT.dprint("End of event script for events.on_trigger_created_entity(%s).", { event }, "line")
end

------------------------------------------------------------------------------------
-- Init
local function init()
  WT.dprint("Entered function init().")
  if WT.debug_in_log then
    game.check_prototype_translations()
  end

--~ local dummy = game.entity_prototypes[WT.fire_dummy_name]

--~ WT.dprint("Fire dummy name: %s\tresistances: %s\thealth: %s\ttrigger_target_mask: %s", {dummy.name, dummy.resistances, dummy.max_health, dummy.trigger_target_mask})

  ------------------------------------------------------------------------------------
  -- Enable debugging if necessary
  WT.debug_in_log = settings.global["WT-debug_to_log"].value

  ------------------------------------------------------------------------------------
  -- Initialize global tables
  global = global or {}
  global.WT_turrets = global.WT_turrets or {}
  global.turret_ticks = global.turret_ticks or {}
--~ WT.show("global.WT_turrets", global.WT_turrets)
  global.fires = global.fires or {}
--~ WT.show("global.fires", global.fires)
  global.fire_dummies = global.fire_dummies or {}
--~ WT.show("global.fire_dummies", global.fire_dummies)
  global.dummy_positions = global.dummy_positions or {}

  global.acids = WT.make_name_list(ignore_or_acid.get_acid())
  WT.acid_types = ignore_or_acid.get_acid()
  global.enemy_types = WT.enemies("get_list")
  global.enemy_healing = WT.enemy_healing(global.enemy_types)
  global.ignore_fires = ignore_or_acid.get_ignorelist()

WT.show("global.acids", {global.acids})
WT.show("WT.acid_types", {WT.acid_types})
WT.show("global.ignore_fires", {global.ignore_fires})
WT.show("global.enemy_types", {global.enemy_types})
WT.show("global.enemy_healing", {global.enemy_healing})

WT.show("Number of turrets", table_size(global.WT_turrets))

  ------------------------------------------------------------------------------------
  -- Make sure our recipe is enabled if it should be
  for f, force in pairs(game.forces) do
    if force.technologies["gun-turret"].researched then
      force.technologies["gun-turret"].researched = false
      force.technologies["gun-turret"].researched = true
      WT.dprint("Reset technology \"turrets\" for force %s.", { f })
    end
  end
WT.show("Number of turrets", table_size(global.WT_turrets))

  ------------------------------------------------------------------------------------
  -- Forces

  -- Create force for fire dummy if it doesn't exist yet.
  if not game.forces[WT.dummy_force] then
    game.create_force(WT.dummy_force)
  end

WT.show("Number of turrets", table_size(global.WT_turrets))

  WT.force_relations = {}

  -- Set relations of dummy force towards other forces
  for name, force in pairs(game.forces) do
    WT.show(tostring(name), table_size(force.players))
    -- Ignore dummy force
    if force.name ~= WT.dummy_force then
      -- If force has players, make it an enemy of fire dummies
      if table_size(force.players) > 0 then
        force.set_friend(WT.dummy_force, false)
        force.set_cease_fire(WT.dummy_force, false)
        -- Store force relations of this force
        WT.force_relations[force.name] = WT.get_enemy_forces(force)
      -- Forces without players are neutral to fire dummies
      else
        force.set_friend(WT.dummy_force, false)
        force.set_cease_fire(WT.dummy_force, true)
      end
    end
    WT.show(tostring(name .. " (friend)"), force.get_friend(WT.dummy_force))
    WT.show(tostring(name .. " (cease_fire)"), force.get_cease_fire(WT.dummy_force))
  end

  -- Set enemy forces water turrets should target. This will allow for easier
  -- filtering when searching the surface for enemies.
  for t, turret in pairs(global.WT_turrets) do
WT.show("t", t)
WT.show("turret.entity", turret.entity and turret.entity.valid)
    if turret.entity.valid then
      WT.get_turret_enemies(turret.entity)
    else
      global.WT_turrets[t] = nil
      WT.dprint("Removed invalid turret %s!", {t})
    end
  end
WT.show("List of forces with enemy forces", WT.force_relations)
WT.show("Turrets", global.WT_turrets)


WT.show("Number of turrets", table_size(global.WT_turrets))


  -- Add event handler for "Picker Dollies"
  if  remote.interfaces["PickerDollies"] and
      remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then

    script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), function(event)
      WT.dprint("Entered event script for dolly_moved_entity_id(%s).", { event }, "line")
      on_moved(event)
      WT.dprint("End of event script for dolly_moved_entity_id(%s).", { event }, "line")
    end)

    log("Registered handler for \"dolly_moved_entity_id\" from \"PickerDollies\".")
  end


  WT.dprint("End of function init().")
end

------------------------------------------------------------------------------------
-- on_load
local function on_load()
  log("Entered function on_load().")

  -- Turn debugging on or off
  WT.debug_in_log = settings.global["WT-debug_to_log"].value

  -- Compatibility with "Picker Dollies" -- add event handler
  if remote.interfaces["PickerDollies"] and
    remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then

    script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), on_moved)
    WT.dprint("Registered handler for \"dolly_moved_entity_id\" from \"PickerDollies\".")
  end

  log("End of function on_load().")
end

------------------------------------------------------------------------------------
-- ENTITY DAMAGED

local function on_entity_damaged(event)
  WT.dprint("Entered function on_entity_damaged(%s).", { WT.print_name_id(event.entity) })
--~ WT.show("event.cause.name", event.cause and event.cause.name)
--~ WT.show("event.entity.name", event.entity and event.entity.name)
--~ WT.show("event.entity.unit_number", event.entity and event.entity.unit_number)
WT.show("event.cause", WT.print_name_id(event.cause))
WT.show("event.entity", WT.print_name_id(event.entity))

WT.show("event.entity.health", event.entity and event.entity.health)
WT.show("event.entity.prototype.max_health", event.entity and event.entity.prototype.max_health)
WT.show("event.damage_type.name", event.damage_type and event.damage_type.name)
WT.show("event.final_damage_amount", event.final_damage_amount)
WT.show("event.final_health", event.final_health)
WT.show("event.force", event.force.name)
WT.show("event", event)


  ------------------------------------------------------------------------------------
  -- Fire/acid dummy was attacked -- remove it immediately if there is no fires/acid
  -- in its location!!
  local entity = event.entity
  local turret = event.cause

  if WT.is_WT_dummy(entity) then
    if not dummy_marks_fire(entity) then
      WT.dprint("Removing %s because it marks no fire.", { WT.print_name_id(entity) })
      remove_fire_and_dummy("dummy", entity.unit_number)

      WT.dprint("Done.")
      -- This may be useful if we have another turret that will always and only attack
      -- fires. (Scripted retargetting is needed only for water turrets!)
      if turret and (turret.name == WT.water_turret_name) and
                    WT.waterturret_priority ~= "default" then
        target_enemy_or_fire(turret)
      end
    end
    return
  end

  ------------------------------------------------------------------------------------
  -- Return if we didn't do the damage -- shouldn't be necessary because of event
  -- filtering by damage type, but let's just play it safe!
  if not WT.is_WT_turret(turret) then
    WT.dprint("Leaving function on_entity_damaged(%s) early -- damage was caused by %s!", {
              WT.print_name(event.entity), (turret and WT.print_name_id(turret) or "something")
    })
    return
  end

  local ammo = turret.fluidbox[1]
  local damage = event.final_damage_amount
  local damage_type = event.damage_type

  ------------------------------------------------------------------------------------
  -- We damaged something that doesn't belong to us!
--~ WT.show("turret.force", turret.force.name)
--~ WT.show("entity.force", entity.force.name)
  if turret.force ~= entity.force then
    -- Our turrets do additional damage to dummies
    if WT.is_WT_dummy(entity) and
        -- Fire dummies are only vulnerable to water and fire extinguisher fluid
        (
          entity.name == WT.fire_dummy_name and
          (damage_type == WT.water_damage_name or damage_type == WT.fire_ex_damage_name)
        ) or
        -- Acid dummies are also vulnerable against steam
        --~ (
          --~ entity.name == WT.acid_dummy_name and (
            --~ damage_type == WT.water_damage_name or
            --~ damage_type == WT.fire_ex_damage_name or
            --~ damage_type == WT.steam_damage_name
          --~ )
        entity.name == WT.acid_dummy_name then
      entity.health = entity.health - 0.5
    end

    -- Modify steam damage according to its temperature (base temperature is 165 °C)
    -- Applying increased damage only makes sense if hot steam was used and
    -- if the damaged entity survived
    --~ if ammo and ammo.name == "steam" and ammo.temperature ~= 165 and entity.health > 0 then
    --~ if ammo and ammo.name == "steam" and ammo.temperature ~= 165 then
--~ WT.dprint("Adjusting damage and entity health for steam temperature %g (factor %s).", {
  --~ ammo.temperature, ammo.temperature / 165
--~ })
      --~ -- Temporarily restore health because base damage has already been applied
      --~ entity.health = entity.health + damage
      --~ -- Calculate increased damage
      --~ damage = damage * ammo.temperature / 165
      --~ -- Subtract increased damage from health
      --~ entity.health = entity.health - damage

--~ WT.show("entity.health after adjusting steam damage", entity.health)
    --~ -- Damage from water and steam is so low that it may be instantly restored if
    --~ -- the damaged entity has healing_per_tick. Not only would this cancel out all
    --~ -- damage, it will also prevent turrets to switching to a new target. Therefore,
    --~ -- we cancel out the healing effect.
    --~ entity.health = entity.health - global.enemy_healing[entity.type][entity.name]
    --~ end
    if turret.name == WT.steam_turret_name then
      local ammo = turret.fluidbox[1]

      if ammo and ammo.temperature ~= 165 then
WT.dprint("Adjusting damage and entity health for steam temperature %g (factor %s).", {
  ammo.temperature, ammo.temperature / 165
})
        -- Temporarily restore health because base damage has already been applied
        entity.health = entity.health + damage
        -- Calculate increased damage
        damage = damage * ammo.temperature / 165
        -- Subtract increased damage from health
        entity.health = entity.health - damage
WT.show("entity.health after adjusting steam damage", entity.health)
      end
    end

    -- Damage from water and steam is so low that it may be instantly restored if
    -- the damaged entity has healing_per_tick. Not only would this cancel out all
    -- damage, it will also prevent turrets to switching to a new target. Therefore,
    -- we cancel out the healing effect.
    if damage_type == WT.water_damage_name or damage_type == WT.steam_damage_name then
        entity.health = entity.health - global.enemy_healing[entity.type][entity.name]
    end
  end
WT.show("Entity health: ", entity.health)
  WT.dprint("End of function on_entity_damaged(%s).", { WT.print_name_id(event.entity) })
end


------------------------------------------------------------------------------------
--                           Registering event handlers                           --
------------------------------------------------------------------------------------

-- These events must always be active!
------------------------------------------------------------------------------------
-- Initialize game
script.on_init(init)

-- Configuration changed
script.on_configuration_changed(function(event)
WT.dprint("Entered event script for on_configuration_changed(%s)", {event})
  -- Water Turret: Something has changed, maybe a setting?
  local WT_changes = event.mod_changes["WaterTurret"]
WT.show("event.mod_startup_settings_changed", event.mod_startup_settings_changed)
  -- Mod is installed now and was installed before, so a setting must have changed.
  if event.mod_startup_settings_changed then
WT.dprint("Mod setting must have changed")
    -- Read all start-up settings again
    WT.read_startup_settings()

    -- Reset target of turrets that shoot at spawners/turrets if these have been
    -- made immune by the changed settings
    local target
    for t, turret in pairs(global.WT_turrets) do
      if turret.entity and turret.entity.valid then
        target = turret.entity.shooting_target
        if target and not (target.valid and WT.enemies(target.type)) then
WT.show("target", WT.print_name_id(target))
WT.show("WT.enemies(target.type)", WT.enemies(target.type))
WT.dprint("Current target of %s: %s", { WT.print_name_id(turret.entity), WT.print_name_id(target) })
          turret.entity.shooting_target = {}

WT.dprint("New target of %s: %s", {
  WT.print_name_id(turret.entity),
  WT.print_name_id(turret.entity.shooting_target)
})
        end
      end
    end

  end

  -- Hardened Pipes compatibility: Reset technology effects?
  if event.mod_changes["hardened_pipes"] or event.mod_startup_settings_changed then
    for t, tech in pairs({
        "turrets", "lubricant", "PCHP-hardened-pipes", "WT-fire-ex-turret"
    }) do

      for f, force in pairs(game.forces) do
        -- Only necessary if the tech has been researched already!
        if game.technology_prototypes[tech] and force.technologies[tech].researched then
WT.dprint("Tech exists and has been researched by force %s!", {force.name})
          -- Unresearch tech to remove effects
          force.technologies[tech].researched = false
          -- Check if all prerequisite techs have been researched
          local prereqs_found = true
          for p, prerequisite in pairs (game.technology_prototypes[tech].prerequisites) do
            if not force.technologies[p].researched then
WT.dprint("Prerequisite has not been researched yet by force %s!", {force.name})
              prereqs_found = false
              break
            end
          end
          -- Enable tech again if all requirements are met
          if prereqs_found then
WT.dprint("Reenabling tech %s for force %s!", {tech, force.name})
            force.technologies[tech].researched = true
          end
        end
      end
    end
  end

  -- Initialize game!
  init(event)
  WT.dprint("End of event script for on_configuration_changed(%s)", {event})
end)

-- Events related to players/forces
for event_name, event in pairs({
  on_player_created              = defines.events.on_player_created,
  on_player_joined_game          = defines.events.on_player_joined_game,
  on_player_changed_force        = defines.events.on_player_changed_force,
  on_player_removed              = defines.events.on_player_removed,
  on_force_created               = defines.events.on_force_created,
  --~ on_runtime_mod_setting_changed = defines.events.on_runtime_mod_setting_changed
}) do

  script.on_event(event, function(event_args)
    WT.dprint("Entered event script for %s ( %s).", { event_name, event_args })
    init(event_args)
    WT.dprint("End of event script for %s ( %s).", { event_name, event_args })
  end)
end

-- Modsetting changed
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  WT.dprint("Entered event script for on_runtime_mod_setting_changed (%s).", { event })

  if event.setting_type == "runtime-global" then
    -- Turrets will slow down friendly targets as well as enemies
    if event.setting == "WT-friendly_target_slow_down" then
      WT.slow_down_all = settings.global["WT-friendly_target_slow_down"].value

    -- Water turrets prioritize fire, enemies, or nothing
    elseif event.setting == "WT-waterturret_preferred_target" then
      WT.waterturret_priority = settings.global["WT-waterturret_preferred_target"].value
      WT.show("Set waterturret_priority", WT.waterturret_priority)

    -- Set radius in which fires are extinguished around a fire dummy
    elseif event.setting == "WT-friendly_target_slow_down" then
      WT.fire_dummy_radius = settings.global["WT-fire-extinguish-radius"].value
      WT.show("Set fire_dummy_radius", WT.fire_dummy_radius)

    -- Enable logging of debugging output
    elseif event.setting == "WT-debug_to_log" then
      local setting = settings.global["WT-debug_to_log"].value
      WT.show("Set debug_in_log", setting)
      WT.debug_in_log = setting
    end

  end
  init(event)

  WT.dprint("End of event script for on_runtime_mod_setting_changed (%s).", { event })
end)








------------------------------------------------------------------------------------
-- Turret was created (for-loop is needed because filters can't be applied to an
-- array of events!)

for event_name, e in pairs({
  on_built_entity       = defines.events.on_built_entity,
  on_robot_built_entity = defines.events.on_robot_built_entity,
  script_raised_built   = defines.events.script_raised_built,
  script_raised_revive  = defines.events.script_raised_revive
}) do
--~ log("WT.turret_list: " .. serpent.block(WT.turret_list))
--~ log("event_name: " .. serpent.block(event_name) .. "\te: " .. serpent.block(e))
  script.on_event(e, function(event)
      WT.dprint("Entered event script for %s.", { event_name })
      on_built(event)
      WT.dprint("End of event script for %s.", { event_name })
    end, {
    {filter = "type", type = WT.turret_type},
    {filter = "name", name = WT.steam_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.water_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.extinguisher_turret_name, mode = "and"},
  })
end


------------------------------------------------------------------------------------
-- Entity was created by trigger event
script.on_event(defines.events.on_trigger_created_entity, function(event)
WT.show("on_trigger_created_entity", event)
  local entity = event.entity

  -- One of our dummies was created -- register dummy and fire!
  if WT.dummy_types[entity.name] and (entity.type ==WT.dummy_type) then
    WT.dprint("Registering dummy %s", {WT.print_name_id(entity)})
    WT.register_fire_dummy(entity)

  -- Remove slow-down sticker?
  elseif not WT.slow_down_all and
          entity.type == "sticker" and
          entity.name == WT.slowdown_sticker_name then
    WT.show("Removing", entity.name)
    remove_slowdown_sticker(event)
  end
end)


------------------------------------------------------------------------------------
-- Fire has been destroyed

script.on_event(defines.events.on_entity_died, function(event)
  WT.dprint("Entered event script for events.on_entity_destroyed(%s).", { event }, "line")

  local id = event.entity


  if id and global.fires[id] then
    WT.dprint("Removing fire %s from global list!", { id })
    remove_fire_and_dummy("fire", id)
  end

  WT.dprint("End of event script for events.on_entity_destroyed(%s).", { event }, "line")
end)


------------------------------------------------------------------------------------
-- Remove fire dummies that mark no fire from surfaces every 30 minutes
script.on_nth_tick(30*60*60, function(event)
  WT.dprint("Entered event script for on_nth_tick(%s).", { event }, "line")
  remove_fire_dummies_from_surface(event)
  WT.dprint("End of event script for on_nth_tick(%s).", { event }, "line")
end)


------------------------------------------------------------------------------------
-- Remove fire dummies that mark no fire from global table every 20 minutes
script.on_nth_tick(20*60*60, function(event)
  WT.dprint("Entered event script for on_nth_tick(%s).", { event }, "line")
  remove_fire_dummies_from_table(event)
  WT.dprint("End of event script for on_nth_tick(%s).", { event }, "line")
end)







------------------------------------------------------------------------------------
-- Turret was rotated
script.on_event(defines.events.on_player_rotated_entity, on_player_rotated_entity)

------------------------------------------------------------------------------------
-- Turret was removed  (for-loop is needed because filters can't be applied to an
-- array of events!)
for event_name, e in pairs({
  on_player_mined_entity        = defines.events.on_player_mined_entity,
  on_robot_mined_entity         = defines.events.on_robot_mined_entity,
  script_raised_destroy         = defines.events.script_raised_destroy,
}) do

  script.on_event(e, function(event)
    WT.dprint("Entered event script for %s.", { event_name })
    remove_turret(event.entity.unit_number)
    WT.dprint("End of event script for %s.", { event_name })
  end, {
    {filter = "type", type = WT.turret_type},
    {filter = "name", name = WT.steam_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.water_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.extinguisher_turret_name, mode = "and"}
  })
end


------------------------------------------------------------------------------------
-- Entity died

local filters = {
    { filter = "type", type = WT.dummy_type },
    { filter = "name", name = WT.fire_dummy_name, mode = "and" },

    { filter = "type", type = WT.dummy_type },
    { filter = "name", name = WT.acid_dummy_name, mode = "and" },

    { filter = "type", type = WT.turret_type, mode = "or" },
    { filter = "name", name = WT.steam_turret_name, mode = "and" },

    { filter = "type", type = WT.turret_type, mode = "or" },
    { filter = "name", name = WT.water_turret_name, mode = "and" },

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.extinguisher_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.extinguisher_turret_water_name, mode = "and"},

}
do
  local enemies = WT.make_name_list(WT.enemies("get_list"))
  for e, enemy in pairs(enemies) do
    table.insert(filters, {
      filter = "type", type = enemy, mode = "or",
    })
  end
end
WT.show("filters", filters)
script.on_event(defines.events.on_entity_died, function(event)
  WT.dprint("Entered event script for on_entity_died(%s).", {
    WT.print_name_id(event.entity)
  }, "line")

  local entity = event.entity
  local cause = event.cause
  local damage_type = event.damage_type
  WT.dprint("%s was killed by %s.", { WT.print_name_id(entity), WT.print_name_id(cause) })

  -- Turret died
  if WT.is_WT_turret(entity) then
    WT.dprint("Turret died!")
    remove_turret(entity.unit_number)
    return

  -- Dummy died
  elseif WT.is_WT_dummy(entity) then
    WT.dprint("%s died! Check if there are fires to extinguish around it.", { WT.print_name_id(entity) })
    extinguish_fire(entity)
    remove_fire_and_dummy("dummy", entity.unit_number)
  end

  -- Retarget if a water turret did the killing and a target is prioritized
  if WT.waterturret_priority ~= "default" and cause and cause.valid and
        WT.is_WT_turret_name(cause, WT.water_turret_name) then

    WT.dprint("%s killed %s: Retarget!",
              {WT.print_name_id(cause),
              WT.print_name_id(entity) or "nil",
    })
    target_enemy_or_fire(cause)
  end

  WT.dprint("End of event script for on_entity_died(%s).", { event }, "line")
  end, filters)


--~ script.on_load(on_load)

------------------------------------------------------------------------------------
-- Entity damaged
script.on_event(defines.events.on_entity_damaged, on_entity_damaged, {
  -- Entities were damaged by our turrets. As most entities with health are immune
  -- to our damage, this will be an enemy or another entity intended to be damaged.
  -- (Check __WaterTurret__/prototypes_with_health.lua for prototypes listed in
  -- prototypes_with_health.attack and prototypes_with_health.vulnerable!)

  -- Increase steam damage for enemy entities; check if fire dummies mark fire!
  {filter = "final-damage-amount", comparison = ">", value = 0},
  {filter = "damage-type", type = WT.steam_damage_name, mode = "and"},

  {filter = "final-damage-amount", comparison = ">", value = 0, mode = "or"},
  {filter = "damage-type", type = WT.water_damage_name, mode = "and"},

  {filter = "final-damage-amount", comparison = ">", value = 0, mode = "or"},
  {filter = "damage-type", type = WT.fire_ex_damage_name, mode = "and"},
})
------------------------------------------------------------------------------------
-- Check turrets on every tick (will bail out immediately if turret's registered action tick
-- is in the future)
script.on_event(defines.events.on_tick, on_tick)

------------------------------------------------------------------------------------
--                          Compatibility with other mods                         --
------------------------------------------------------------------------------------




------------------------------------------------------------------------------------
--                    FIND LOCAL VARIABLES THAT ARE USED GLOBALLY                 --
--                              (Thanks to eradicator!)                           --
------------------------------------------------------------------------------------

--[[setmetatable(_ENV,{

  __newindex = function (self,key,value) --locked_global_write
    error('\n\n[ER Global Lock] Forbidden global *write*:\n'
      .. serpent.line{key = key or '<nil>',value = value or '<nil>'} .. '\n')
  end,
  __index   =function (self,key) --locked_global_read
    if not (key == "game" or key == "mods") then
      error('\n\n[ER Global Lock] Forbidden global *read*:\n'
        .. serpent.line{key = key or '<nil>'} .. '\n')
    end
  end ,
})

--]]

