local prototypes_wh = require("prototypes_with_health")
local math2d = require("math2d")
local util = require("util")

return function(mod_name)
  local common = {}

  -- Make list of names that can be used for filters
  common.make_name_list = function(tab)
    local list = {}

    if tab and type(tab) == "table" then
      for name, bool in pairs(tab) do
        list[#list + 1] = name
      end
    end

    return list
  end


  local function set_color(turret)
    ---@diagnostic disable-next-line type-mismatch
    local color = settings.startup[turret .. "-color"].value
    -- Normalize hexadecimal numbers by removing prefix!
    if string.match(color, "^%s*#%x+%s*$") then
      color = string.gmatch(color, "%x+")()
    end


    -- Hex-code color
    if string.match(color, "^([%x]+)$") and string.len(color) == 6 then

      color = util.color(color)

    -- RGB triples
    elseif string.match(color, "^%s*([%d.]+),%s*([%d.]+),%s*([%d.]+)%s*$") then
      local rgb = {}
      local valid = true
      local cnt = 0

      for c in string.gmatch(color, "[%d.]+") do
        cnt = cnt + 1
        rgb[cnt] = tonumber(c)
        if not rgb[cnt] or (rgb[cnt] < 0) or (rgb[cnt] > 255) then
          valid = false
          break
        end
      end
      if valid then
        color = { r = rgb[1], g = rgb[2], b = rgb[3], a = 1}
      else
        color = nil
      end

    -- Wrong color code
    else
      color = nil
    end

    if not color then
      log(serpent.line(color) .. " is not a valid color. Using default color for " .. turret .. "!")
    end

    return color
  end

--~ ------------------------------------------------------------------------------------
--~ -- Make list of forces that are enemy of the turret force and store it with the
--~ -- turret data in the global table.
--~ prototypes_with_health.get_enemy_forces = function(turret)
  --~ log(string.format("End of function get_enemy_forces(%s).", turret))

  --~ if not (turret and turret.valid and storage.WT_turrets[turret.unit_number]) then
    --~ error(string.format("%s (%s) is not a valid turret!",
                          --~ turret and turret.name or "nil",
                          --~ turret and turret.unit_number or turret.index or "nil"))
  --~ end

  --~ local ret = {}

  --~ for f, force in pairs(game.forces or {}) do
    --~ if (force ~= turret.force) and
        --~ not (force.get_friend(turret.force) or force.get_cease_fire(turret.force)) then
      --~ ret[#ret + 1] = force.name
    --~ end
  --~ end

  --~ log(string.format("End of function get_enemy_forces(%s). (Return: %s)", turret, ret))
  --~ return ret
--~ end

  -- Read startup settings
  common.read_startup_settings = function()
    common.action_delay = settings.startup["WT-action-delay"].value * 60
    -- Immunity
    common.spawner_immunity = settings.startup["WT-immunity-spawner"].value
    common.turret_immunity = settings.startup["WT-immunity-turret"].value
    -- Clean or ignore acid splashes?
    common.clean_acid_splashes = settings.startup["WT-turrets_clean_acid"].value
    --~ -- Extinguish fires in that radius around dummy if dummy dies
    --~ common.fire_dummy_radius = settings.startup["WT-fire-extinguish-radius"].value
    -- Turrets prioritize targets by health
    common.health_factor = { ["high-health"] = -1, ["ignore-health"] = 0, ["low-health"] = 1}
    common.health_factor = common.health_factor[settings.startup["WT-preferred-target"].value]
    -- Damage modifiers
    common.steam_damage_modifier = settings.startup["WT-steam-damage-modifier"].value

    -- Tint of turrets
    common.water_turret_tint = set_color(common.water_turret_name) or
                                { r = 0.25, g = 0.677, b = 0.75, a = 1 }
    --~ common.extinguisher_turret_tint = { r = 0.981, g = 0.059, b = 0.059, a = 1}
    common.extinguisher_turret_tint = set_color(common.extinguisher_turret_name) or
                                      { r = 0.961, g = 0.181, b = 0.181, a = 0}

    -- Modifier for pressure (affects stream animation speed, damage, and fluid consumption)
    common.water_turret_pressure = settings.startup["WT-water-turret-pressure"].value
    common.extinguisher_turret_pressure = settings.startup["WT-extinguisher-turret-pressure"].value

    -- Damage modifier for Fire extinguisher fluid
    common.extinguisher_fluid_damage_modifier =
        settings.startup["WT-extinguisher-fluid-damage-modifier"].value
    -- Damage modifier for Fire extinguisher turrets (will affect water and extinguisher fluid)
    common.extinguisher_turret_damage_modifier =
        --~ settings.startup["WT-extinguisher-turret-damage-modifier"] and
        --~ settings.startup["WT-extinguisher-damage-modifier"].value or 5
        settings.startup["WT-extinguisher-turret-damage-modifier"] .value
    --~ common.waterturret_priority = settings.startup["WT-waterturret_preferred_target"].value
    -- Slowdown factor
    common.slowdown_factor = settings.startup["WT-target-slowdown-factor"].value / 100
    -- Turret range
    common.water_turret_range = settings.startup["WT-water-turret-range"].value
    common.extinguisher_turret_range = settings.startup["WT-extinguisher-turret-range"].value
    -- Mod compatibility
    -- Enable hardened pipes?
    common.hardened_pipes = settings.startup["WT-fire-extinguish-hardened"] and
                            settings.startup["WT-fire-extinguish-hardened"].value
    -- Enable Global Variable Viewer?
    common.debug_gvv = settings.startup["WT-enable_gvv_support"] and
                       settings.startup["WT-enable_gvv_support"].value
    -- Add new BI recipe for Fire extinguisher turrets or replace ingredient?
    common.BI_adds_new_recipe = settings.startup["WT-recipe-BI"] and
                                settings.startup["WT-recipe-BI"].value
  end


  -- Set mod name and base path
  common.mod_name = mod_name or (script and script.mod_name)
  common.mod_root = "__" .. common.mod_name .. "__/"


  -- Turret type and names
  common.turret_type = "fluid-turret"
  common.steam_turret_name = "WT-steam-turret"
  common.water_turret_name = "WT-water-turret"
  common.extinguisher_turret_name = "WT-fire-ex-turret"
  common.extinguisher_turret_water_name = "WT-fire-ex-turret-water"
  -- Searchable list of turret names
  common.turret_names = {
    [common.steam_turret_name] = true,
    [common.water_turret_name] = true,
    [common.extinguisher_turret_name] = true,
    [common.extinguisher_turret_water_name] = true,
  }
  --~ common.turret_list = common.make_name_list(common.turret_names)

  -- Needed to calculate the area outside of a turrets reach -- will be set the first
  -- time that can_shoot() is called!
  common.water_turret_blind_angle_tan = nil

  -- Read startup settings
  common.read_startup_settings()

  -- Read map settings
  if game or script then
    common.waterturret_priority = settings.global["WT-waterturret_preferred_target"].value
    -- Extinguish fires in that radius around dummy if dummy dies
    common.fire_dummy_radius = settings.global["WT-fire-extinguish-radius"].value
    common.slow_down_all = settings.global["WT-friendly_target_slow_down"].value
    common.debug_to_log_setting = settings.global["WT-debug_to_log"].value
  end

  common.ammo_category = "WT-ammo"

  -- Fluid name
  common.fire_ex_fluid = "WT-fire_ex_fluid"

  -- Fluid tint
  --~ common.water_color = f["water"] and  f["water"].base_color
  --~ common.steam_color = f["steam"] and f["steam"].base_color
  --  common.fire_ex_fluid_tint = { r = 0.816, g = 0.820, b = 0.106, a = 1.000 }
  common.fire_ex_fluid_tint = { r = 1, g = 0.961, b = 0.882, a = 1.000 } --#FFF5E1
  --~ common.fire_ex_fluid_tint = { r = 1, g = 1, b = 1, a = 1.000 }

  -- Searchable list of fluid names
  common.fluid_names = {
    ["water"] = true,
    ["steam"] = true,
    [common.fire_ex_fluid] = true,
  }

  -- Damage types
  common.steam_damage_name = "WT-steam"
  common.water_damage_name = "WT-water"
  common.fire_ex_damage_name = "WT-extinguisher-fluid"

  -- Searchable list of damage types
  common.damage_types = {
    [common.steam_damage_name] = true,
    [common.water_damage_name] = true,
    [common.fire_ex_damage_name] = true,
  }
  -- Base damage amount of water and steam turrets
  common.water_base_damage_amount = 0.005

  -- Trigger target types
  common.trigger_target_mobile = "WaterTurrets_mobile_target"
  common.trigger_target_fire_dummy = "WaterTurrets_fire_dummy"
  common.trigger_target_acid_dummy = "WaterTurrets_acid_dummy"
  common.trigger_target_ignore = "WaterTurrets_ignore_target"

  -- Sticker names
  common.slowdown_sticker_name = "WaterTurrets_slowdown_sticker"

  -- Dummies
  --~ common.dummy_type = "simple-entity-with-force"
  common.dummy_type = "combat-robot"
  common.dummy_force = "WT-fire-dummy"

  common.acid_dummy_name = "WT-acid-dummy"
  common.fire_dummy_name = "WT-fire-dummy"

  -- Searchable list of dummy names
  common.dummy_types = {
    [common.acid_dummy_name] = true,
    [common.fire_dummy_name] = true,
  }
  common.dummy_list = common.make_name_list(common.dummy_types)

  -- Removed animation: We place a real fire now as created_effect of
  -- the fire-dummy prototype!
  --~ -- Animations rendered on dummy position
  --~ common.dummy_animation_name = "WT-fire-dummy-animation"

  -- Fire placed on top of normal fires
  common.fake_fire_name = "WT-fire"
  -- Burnt patch placed after fire has been extinguished or is expired
  common.burnt_patch = "WT-fake-fire-burnt-patch"

   -- This are functions that return an array!
  common.enemies = prototypes_wh.attack
  common.enemy_healing = prototypes_wh.healing
  --~ common.get_enemy_forces = prototypes.get_enemy_forces
--~ log("enemy_healing: " .. serpent.block(common.enemy_healing))
  -- Searchable list of acid names
  common.acid_types = {}
  -- Searchable list of forces with enemy forces
  common.force_relations = {}

  -- Just define these to avoid tests not working because of a typo!
  common.spawner_type = "unit-spawner"
  common.worm_type = "turret"
  common.artillery_type = "artillery-turret"

  ------------------------------------------------------------------------------------
  --                                   Debugging                                    --
  ------------------------------------------------------------------------------------
  -- Debugging output in the game is not meant for players, so there won't be a
  -- setting for it. Activate it here if you really need it!
  common.debug_in_game = false

  -- Debugging to log will be active if the dummy mod is active
  if  (mods and mods["_debug"]) or (script and script.active_mods["_debug"]) then
    common.debug_in_log = true
  end

  -- Debugging can also be activated with the global setting. However, this isn't
  -- available in the data stage yet, so we OR its value with the current state of
  -- common.debug_in_log.
  if common.debug_to_log_setting then
    common.debug_in_log = common.debug_in_log or common.debug_to_log_setting
  end
--~ log("common.debug_in_log: " .. tostring(common.debug_in_log))

  -- Output debugging text
  common.dprint = function(msg, tab, ...)
    local args = {}
    local line
--~ log("msg: " .. msg .. "\ttab: " .. serpent.line(tab))
    -- Use serpent.line instead of serpent.block if this is true!
    if common.debug_in_log or common.debug_in_game then
      line = ... and
                  (string.lower(...) == "line" or string.lower(...) == "l") and
                  true or false

    --~ if common.debug_in_log or common.debug_in_game then
      if type(tab) ~= "table" then
        tab = { tab }
      end
--~ log("tab: " .. serpent.line(tab))
--~ log("table_size(tab): " .. table_size(tab) .. "\t#tab: " .. #tab)
      local v
      --~ for k in pairs(tab or {}) do
      for k = 1, #tab do
        v = tab[k]
--~ log("k: " .. k .. "\tv: " .. serpent.line(v))
        -- NIL
        if v == nil then
          args[#args + 1] = "NIL"
--~ log(serpent.line(args[#args]))
        -- TABLE
        elseif type(v) == "table" then
          --~ if table_size(v) == 0 then
            --~ args[#args + 1] = "{}"
            --~ args[#args + 1] = "EMPTY_TABLE"
          --~ else
            --~ args[#args + 1] = line and { [k] = serpent.line(v) } or { [k] = serpent.block(v) }
            --~ args[#args + 1] = line and serpent.line({ [k] = v }) or
                                        --~ serpent.block({ [k] = v })
          --~ end
          args[#args + 1] = line and serpent.line(table.deepcopy(v)) or
                                      serpent.block(table.deepcopy(v))
--~ log(serpent.line(args[#args]))
        -- OTHER VALUE
        else
          args[#args + 1] = v
--~ log(serpent.line(args[#args]))
        end
      end
      if #args == 0 then
        args[1] = "nil"
      end
      args.n = #args
--~ log("args: " .. serpent.block(args))
      if common.debug_in_log then
        log(string.format(tostring(msg), table.unpack(args)))
      end
      if common.debug_in_game and game then
        game.print(string.format(tostring(msg), table.unpack(args)))
      end
    end
    --~ if game then
      --~ common.debugging_profiler.stop()
      --~ log(common.debugging_profiler)
    --~ end
  end

  -- Simple helper to show values
  common.show = function(desc, term)
    if common.debug_in_log or (game and common.debug_in_game) then
      --~ common.dprint(tostring(desc) .. ": %s", term or "NIL")
      common.dprint(tostring(desc) .. ": %s", type(term) == "table" and { term } or term)
    end
  end

  -- Print "entityname (id)"
  common.print_name_id = function(entity)
    local id
    local name = "unknown entity"
--~ common.show("entity.name", entity and entity.name or "")
--~ common.show("entity.type", entity and entity.type or "")

    if entity and entity.valid then
    -- Stickers don't have an index or unit_number!
      --~ id =  (entity.type == "sticker" and entity.type) or
            --~ entity.unit_number or entity.type
      id = entity.unit_number or entity.type

      name = entity.name
    end

    --~ return name .. " (" .. tostring(id) .. ")"
    --~ return string.format("%s (%s)", name, id)
    return (name or "nil")  .. "(" .. (id or "nil") .. ")"
  end

  -- Print "entityname"
  common.print_name = function(entity)
    return entity and entity.valid and entity.name or ""
  end

  ------------------------------------------------------------------------------------
  --                                     Recipe                                     --
  ------------------------------------------------------------------------------------
  common.compile_recipe = function(recipe, recipe_data_normal, recipe_data_expensive)
--~ common.show("recipe", recipe)
--~ common.show("data", recipe_data_normal)

    -- recipe is required
    if recipe then
      recipe.normal = recipe.normal or {}
      recipe.expensive = recipe.expensive or {}
    else
      error("Recipe " .. tostring(recipe) .. " is not valid!")
    end
    -- recipe_data is required, recipe_data_expensive is optional
    if not recipe_data_normal then
      error("Missing recipe data!")
    end


    local i_type, i_name, i_amount
    for k, v in pairs(recipe_data_normal) do
        --~ recipe[k] = v
        --~ recipe.normal[k] = v
      if k ~= "ingredients" then
        recipe[k] = v
        recipe.normal[k] = v
      else
        recipe[k] = {}
        recipe.normal[k] = {}

        for _, i in pairs(recipe_data_normal.ingredients) do
--~ common.dprint("ingredient: %s (%g fields)", { i, table_size(i) })
          if table_size(i) == 2 then
            i_type = "item"
            i_name = i[1]
            i_amount = i[2]
          elseif table_size(i) == 3 then
            i_type = i.type
            i_name = i.name
            i_amount = i.amount
          else
            common.dprint("Something unexpected happened -- ingredient table does not have 2 or 3 fields! (%s)", { i })
          end

          table.insert(recipe[k], { type = i_type, name = i_name, amount = i_amount })
          table.insert(recipe.normal[k], { type = i_type, name = i_name, amount = i_amount })
        end
      end
    end

    -- recipe_data_expensive may be complete or partial recipe data, so we copy
    -- the normal recipe and replace the settings explicitly passed to this function.
    recipe.expensive = table.deepcopy(recipe.normal)

    -- Replace settings that are given in recipe_data_expensive
    if recipe_data_expensive then
      for k, v in pairs(recipe_data_expensive or {}) do
        recipe.expensive[k] = v
      end
    -- If recipe_data_expensive doesn't exist, double the amount of all ingredients
    else
--~ common.dprint ("expensive ingredients: %s", recipe.expensive.ingredients)
      for k, v in pairs(recipe.expensive.ingredients or {}) do
        v.amount = v.amount * 2
      end
    end
common.show("compiled recipe", recipe)

    return recipe
  end

  ------------------------------------------------------------------------------------
  --             Check if unlock technology already contains our recipe             --
  ------------------------------------------------------------------------------------
  common.unlocked_already = function(tech, recipe)
    if not (tech) then
      error("Technology " .. tostring(tech) .. " is not valid!")
    elseif not (recipe) then
      error("\"" .. tostring(recipe) .. "\" is not a valid recipe!")
    end

    local defined = false

    for _, effect in pairs(tech.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe then
        defined = true
        break
      end
    end

    return defined
  end


  ------------------------------------------------------------------------------------
  --                         Check if an entity is our dummy                        --
  ------------------------------------------------------------------------------------
  common.is_WT_dummy = function(dummy)
    common.dprint("Entered function is_WT_dummy(%s).", {common.print_name_id(dummy)})

    return (dummy and dummy.valid) and
            (dummy.type == common.dummy_type) and common.dummy_types[dummy.name]
  end


  ------------------------------------------------------------------------------------
  --               Check if an entity is one of our turrets (by name)               --
  ------------------------------------------------------------------------------------
  common.is_WT_turret_name = function(turret, name)
    common.dprint("Entered function is_WT_turret_name(%s, %s).",
                  {common.print_name_id(turret), name}, "line")

    return (turret and turret.valid and name and type(name) == "string") and
            (turret.type == common.turret_type and turret.name == name) and
              true or false
  end
  -- Just an alias!
  common.is_WT_turret_type = common.is_WT_turret_name


  ------------------------------------------------------------------------------------
  --                    Check if an entity is one of our turrets                    --
  ------------------------------------------------------------------------------------
  common.is_WT_turret = function(turret)
    common.dprint("Entered function is_WT_turret(%s).",
                  {turret and turret.valid and turret.name or "nil"})

    return (turret and turret.valid) and
            (turret.name and common.turret_names[turret.name]) and
            (turret.type and turret.type == common.turret_type) and
            true or false
  end

  ------------------------------------------------------------------------------------
  --      Check for min_range <= distance <= max_range  (returns true or false)     --
  ------------------------------------------------------------------------------------
  common.is_in_range = function(turret, target)
    common.dprint("Entered function is_in_range(%s, %s).",
                  { common.print_name(turret), target })

    -- Check arguments
    if not (turret and turret.valid) then
      error(string.format("%s is not a valid turret!", turret))
    end
    if not (target and target.position) and
        not (target and (target.x and target.y) or (target[1] and target[2]) ) then
      error("%s is not a valid target!", target)
    end

common.show("target", target)
    -- Get distance
    local tu = turret.position
    local ta = target.position or target
common.show("ta", ta)
    local x, y = (tu.x or tu[1]) - (ta.x or ta[1]), (tu.y or tu[2]) - (ta.y or ta[2])
common.show("x", x)
common.show("y", y)
    local distance = math.sqrt(x*x + y*y)

    -- We searched a radius of max range, so we only need to check for min_range here!
    --~ local ret = (distance >= global.WT_turrets[turret.unit_number].min_range and
                  --~ distance <= global.WT_turrets[turret.unit_number].range)
    local ret = (distance > storage.WT_turrets[turret.unit_number].min_range and
                  distance < storage.WT_turrets[turret.unit_number].range)
    common.dprint("End of function is_in_range(%s, %s). (Distance: %s. Return: %s)",
                  { common.print_name(turret), target, distance, ret })
    --~ return (distance >= storage.WT_turrets[turret.unit_number].min_range and
              --~ distance <= storage.WT_turrets[turret.unit_number].range)
    return ret
  end


  ------------------------------------------------------------------------------------
  --                        Check if two forces are enemies                         --
  ------------------------------------------------------------------------------------
  common.is_enemy = function(force_a, force_b)
    common.dprint("Entered function is_enemy(%s, %s).",
                  { common.print_name(force_a), common.print_name(force_b) })

    force_a = (type(force_a) == "string" and game.forces[force_a]) or
              (type(force_a) == "number" and game.forces[force_a]) or
              force_a.force or force_a
    force_b = (type(force_b) == "string" and game.forces[force_b]) or
              (type(force_b) == "number" and game.forces[force_b]) or
              force_b.force or force_b

    if not (force_a and force_a.valid) then
      error(string.format("%s is not a valid force!", force_a))
    elseif not (force_b and force_b.valid) then
      error(string.format("%s is not a valid force!", force_b))
    end

    local ret = (force_a ~= force_b) and
                  not (force_a.get_friend(force_b) or force_a.get_cease_fire(force_b))

    common.dprint("End of function is_enemy(%s, %s). (Return: %s)",
                  { common.print_name(force_a), common.print_name(force_b), ret })
    return ret
  end


  --~ ------------------------------------------------------------------------------------
  --~ --                     Get forces that are enemy to this force                    --
  --~ ------------------------------------------------------------------------------------
  --~ common.get_enemy_forces = function(force)
    --~ return prototypes.get_enemy_forces(force)
  --~ end


  ------------------------------------------------------------------------------------
  -- Make list of forces that are enemy of the turret force and store it with the
  -- turret data in the storage table.
  common.get_enemy_forces = function(check_force)
    common.dprint("Entered function get_enemy_forces(%s).", {check_force})

    check_force = check_force and (
                    -- Force
                    (check_force.valid and game.forces[check_force.name]) or
                    -- Force name
                    (type(check_force) == "string" and game.forces[check_force]) or
                    -- Force index
                    (type(check_force) == "number" and game.forces[check_force]) or
                    -- Force from entity
                    (check_force.valid and check_force.force)
                  )

    if not check_force then
      error(string.format("%s is not a valid force!", check_force or "nil"))
    end

    local ret = {}

    for f, force in pairs(game.forces or {}) do
      if (force ~= check_force) and
          not (force.get_friend(check_force) or force.get_cease_fire(check_force)) then
        ret[#ret + 1] = force.name
      end
    end

    common.dprint("End of function get_enemy_forces(%s). (Return: %s)", {check_force, serpent.block(ret)})
    return ret
  end


  ------------------------------------------------------------------------------------
  --                Get list of forces that are enemies of the turret               --
  ------------------------------------------------------------------------------------
  common.get_turret_enemies = function(turret)
    common.dprint("Entered function get_turret_enemies(%s).",
                  { common.print_name(turret) })

    if not common.is_WT_turret(turret) then
      error(string.format("%s is not a valid turret!", turret))
    elseif not (turret.force and turret.force.valid) then
      error(string.format("%s doesn't have a force!", common.print_name_id(turret)))
    end

common.show("common.get_enemy_forces", common.get_enemy_forces(turret))
common.show("type(common.get_enemy_forces)", type(common.get_enemy_forces(turret)))

    local force
    if turret.name == common.water_turret_name then
      force = turret.force.name
      if not (force and common.force_relations[force]) then
        common.force_relations[force] = common.get_enemy_forces(turret)
      end
      storage.WT_turrets[turret.unit_number].enemy_forces = common.force_relations[force]
    end

    common.dprint("End of function get_turret_enemies(%s).", { common.print_name(turret) })
  end


  ------------------------------------------------------------------------------------
  --         Get the rectangular area in the direction the turret is facing         --
  ------------------------------------------------------------------------------------
  common.get_turret_area = function(turret, direction)
    common.dprint("Entered function get_turret_area(%s).", {common.print_name_id(turret)})

    if not common.is_WT_turret(turret) then
      error("Wrong argument -- not a valid turret: " .. serpent.block(turret))
    end
    if direction and not type(direction) == "number" then
      error("Wrong argument -- not a valid direction: " .. serpent.block(direction))
    end

    local x = turret.position.x or turret.position[1]
    local y = turret.position.y or turret.position[2]
    --~ common.show("x", x)
    --~ common.show("y", y)
    --~ common.show("direction", turret.direction)
    local left_top, right_bottom
    local range = storage.WT_turrets[turret.unit_number] and
                    storage.WT_turrets[turret.unit_number].range
    if not range then
      range = turret.prototype.attack_parameters.range
      storage.WT_turrets[turret.unit_number].range = range
    end

    local direction = direction or turret.direction

    -- Turret facing North
    if direction == defines.direction.north then
      left_top = { x - range, y - range }
      right_bottom = { x + range, y }
    -- Turret facing South
    elseif direction == defines.direction.south then
      left_top = {x - range, y}
      right_bottom = {x + range, y + range}
    -- Turret facing East
    elseif direction == defines.direction.east then
      left_top = {x, y - range}
      right_bottom = {x + range, y + range}
    -- Turret facing West
    elseif direction == defines.direction.west then
      left_top = {x - range, y - range}
      right_bottom = {x, y + range}
    -- This should never be reached!
    else
      error(string.format(
        "Something unexpected has happened: %s has direction %s, which is not a cardinal direction.", common.print_name_id(turret), turret.direction)
      )
    end

    common.dprint("End of function get_turret_area(%s).", {common.print_name_id(turret)})
    --~ if storage.WT_turrets[turret.unit_number] then
      --~ if storage.WT_turrets[turret.unit_number].render_area then
        --~ rendering.destroy(storage.WT_turrets[turret.unit_number].render_area)
      --~ end
      --~ storage.WT_turrets[turret.unit_number].render_area = rendering.draw_rectangle{left_top = left_top, right_bottom = right_bottom, color = {r = 1, g = 1, b = 1, a = .1}, filled = true, surface = turret.surface}
      --~ rendering.draw_circle{color= {r = 0.1, g = 0.1, b = 0, a = 0.1}, radius = range, filled = true, target = turret.position, surface = turret.surface}
    --~ end

    return { left_top = left_top, right_bottom = right_bottom }
  end


  ------------------------------------------------------------------------------------
  --                       Check if target is in turret range                       --
  ------------------------------------------------------------------------------------
  common.can_shoot = function(turret, position)
    common.dprint("Entered function can_shoot(%s,%s) on tick %g.",
                  { common.print_name_id(turret), position or "nil", game.tick })

    turret = (turret and turret.valid and storage.WT_turrets[turret.unit_number])
    if not turret then
      error("Wrong argument -- not a valid turret: " .. serpent.block(turret))
    elseif not (position and (position.x or position[1]) and
                              (position.y or position[2])) then
      error("Wrong argument -- not a valid target: " .. serpent.block(position))
    end

    local target_x, target_y, turret_x, turret_y, tmp
    target_x = position.x or position[1]
    target_y = position.y or position[2]
    turret_x = turret.entity.position.x or turret.entity.position[1]
    turret_y = turret.entity.position.y or turret.entity.position[2]

    local ret = false

    local area = turret.area
    -- Precalculate the tangens of the turrets' blind angle just once -- it's a constant
    -- that won't change until Factorio is restarted!
    if not common.water_turret_blind_angle_tan then
      local angle
      local proto = prototypes.get_entity_filtered({
        { filter = "type", type = common.turret_type },
        { filter = "name", name = common.water_turret_name, mode = "and" }
      })
common.show("proto name", proto[common.water_turret_name].name)
common.show("proto[common.water_turret_name]", proto[common.water_turret_name])
      if proto[common.water_turret_name]  then
        -- Turning range is symmetric along the turret' center, so we need to
        -- consider only half of that. Divide by 2 -- or multiply the value by
        -- 180 instead of 360!
        local angle = (proto[common.water_turret_name].attack_parameters.turn_range * 180)
        -- The blind area of the turret is formed by the 2 right-angle triangles ABC
        -- where A is the turret position, B is the target's x-value (y = turrets's y),
        --  and C the intersection of the line from A at $angle and a line from B at
        -- 90°. So we're not interested in the turning angle, but its complement!
        angle = math.rad(90 - angle)
        common.water_turret_blind_angle_tan = math.tan(angle)
      else
        error(string.format("Prototype for %s doesn't exist!", common.water_turret_name))
      end
    end


    -- Check that target is in shooting range
    if common.is_in_range(turret.entity, position) then
      -- For easier calculation rotate dummy position and turret area by 90°
      if turret.entity.direction == defines.direction.east or
          turret.entity.direction == defines.direction.west then
        --~ area = common.get_turret_area(turret.entity, turret.entity.direction)
common.dprint("target_x: %s\ttarget_y: %s", {target_x, target_y})
        target_x, target_y = target_y, -target_x
        common.dprint("Rotated target position to %s", {{target_x, target_y}})
      end


      -- Normalizing to absolute values makes that usable for North and South
      local y = math.abs(target_y - turret_y)
      local x = math.abs(target_x - turret_x)
--~ common.show("angle", common.water_turret_blind_angle_tan)
common.show("turret_x", turret_x)
common.show("turret_y", turret_y)
common.show("x", x)
common.show("y", y)
common.show("math.tan(angle)", common.water_turret_blind_angle_tan)

      -- The blind area of the turret is formed by the 2 right-angle triangles ABC
      -- where A is the turret position, B is the target's x-value (y = turrets's y),
      --  and C the intersection of the line from A at $angle and a line from B at
      -- 90°. If y is greater than the distance BC, the turrect can reach the position.
      if y > x * common.water_turret_blind_angle_tan then
        ret = true
      end
    else
common.dprint("Target position is not in range!")
    end

    common.dprint("End of function can_shoot(%s,%s) on tick %g. (Return: %s)",
                  { common.print_name_id(turret), position or "nil", game.tick, ret })

    return ret
  end





  ------------------------------------------------------------------------------------
  --                           Register fires and dummies                           --
  ------------------------------------------------------------------------------------
  common.register_fire_dummy = function(dummy)
    common.dprint("Entered function register_fire_dummy (%s)", {common.print_name_id(dummy)})
    if not (dummy and dummy.valid) then
      error(string.format("%s is not a valid dummy!", dummy))
    end

--~ local test = dummy.surface.find_entities_filtered({type = "fire", position = dummy.position})
--~ common.show("Fires at dummy position", test)
--~ test = dummy.surface.find_entities_filtered({type = common.dummy_type})
--~ common.show("Dummies on surface", test)
--~ for d, dummy in pairs(test) do
  --~ common.dprint("d: %s\tunit_number: %s", {d, dummy.unit_number})
--~ end
    -- Change attributes of dummy
    local dummy_id = dummy.unit_number

    dummy.active = false
    -- Removed animation: We place a real fire now as created_effect of
    -- the fire-dummy prototype!
    --~ if dummy.name == common.fire_dummy_name then
      --~ local anim = rendering.draw_animation({
        --~ animation = common.dummy_animation_name,
        --~ target = dummy,
        --~ surface = dummy.surface,
        --~ render_layer = "ground-patch",
        --~ forces = {"player"}
      --~ })
--~ common.show("anim", anim)
    --~ end
    dummy.force = common.dummy_force
--~ local x = dummy.position.x or dummy.position[1]
--~ local y = dummy.position.y or dummy.position[2]
--~ local area = {{x-1, y-1}, {x+1, y+1}}
--~ common.show("area", area)
    local fire = dummy.surface.find_entities_filtered({
      type = "fire",
      position = dummy.position,
      --~ radius = 1
      --~ area = area
    })[1]
common.dprint("fire: %s\tposition: %s", {common.print_name_id(fire), fire.position})
common.dprint("dummy: %s\tposition: %s", {common.print_name_id(dummy), dummy.position})


    if fire and fire.valid then
common.dprint("Fire is valid -- registering!")
      -- Add data to tables
      local fire_id = script.register_on_object_destroyed(fire)
      local fire_data = {
        dummy_entity = dummy,
        dummy_id = dummy_id,
        fire_entity = fire,
        fire_id = fire_id,
      }

common.show("fire_data", fire_data)
      storage.fire_dummies[dummy_id] = fire_data
      storage.fires[fire_id] = fire_data

      local x = dummy.position.x or dummy.position[1]
      local y = dummy.position.y or dummy.position[2]

      storage.dummy_positions[x] = storage.dummy_positions[x] or {}
      storage.dummy_positions[x][y] = dummy_id

      --~ storage.fire_positions[x] = storage.fire_positions[x] or {}
      --~ storage.fire_positions[x][y] = fire_id
      end
  end




  --~ ------------------------------------------------------------------------------------
  --~ --        Exchange steam and water turrets if fluidbox contains wrong ammo        --
  --~ --        (Returns nil for invalid turrets, or id (unit_number) of turret)        --
  --~ ------------------------------------------------------------------------------------
  --~ common.swap_turrets = function(id)
    --~ common.dprint("Entered function swap_turrets(%s).", {id})

    --~ ------------------------------------------------------------------------------------
    --~ --                               Bail out on errors                               --
    --~ ------------------------------------------------------------------------------------
    --~ -- Invalid argument
    --~ if (not id) or (type(id) ~= "number") then
      --~ error("\"" .. tostring(id) .. "\" is not a valid turret id!")
    --~ -- No turret stored with this ID
    --~ elseif not storage.WT_turrets[id] then
      --~ error("No turret with id " .. tostring(id) .. " has been registered!")
    --~ -- Invalid turret
    --~ elseif not storage.WT_turrets[id].entity.valid then
      --~ storage.WT_turrets[id] = nil
      --~ common.dprint("Removed expired id %s from list of registered turrets.", {id})
      --~ return nil
    --~ end

    --~ ------------------------------------------------------------------------------------
    --~ --                                Local definitions                               --
    --~ ------------------------------------------------------------------------------------

--~ common.dprint ("Looking for turret with id %s.", {id})
--~ common.dprint("storage.WT_turrets[%g]: %s", { id, storage.WT_turrets[id] } )

    --~ local turret = storage.WT_turrets[id].entity
    --~ local new_turret = nil
    --~ local input = nil
    --~ local output = nil
    --~ local neighbours = turret.neighbours and turret.neighbours[1] or nil
    --~ local t_fluid = turret.get_fluid_contents()
    --~ -- Set neighbours to nil if it's an empty table -- otherwise tests won't work!
    --~ if neighbours and table_size(neighbours) == 0 then neighbours = nil end

--~ common.dprint ("Neighbours of %s: %s ", {turret.name, neighbours and neighbours.name or "none"})

--~ common.dprint("t_fluid: %s", t_fluid)
--~ common.dprint("t_fluid.steam and turret.name == \"%s\": %s", {common.water_turret_name, t_fluid.steam and turret.name == common.water_turret_name and true or false})
--~ common.dprint("t_fluid.water and turret.name == \"%s\": %s", {common.steam_turret_name, t_fluid.water and turret.name == common.steam_turret_name and true or false})
    --~ ------------------------------------------------------------------------------------
    --~ --                        Leave early if everything is OK                         --
    --~ ------------------------------------------------------------------------------------
    --~ -- Turret is not connected to a pipe and doesn't contain fluid -- wait until it is
    --~ -- hooked up and useful!
--~ common.show("turret.get_fluid_contents()", turret.get_fluid_contents())
    --~ if not neighbours then
      --~ common.dprint("Leave early: %s is not hooked up!", {common.print_name_id(turret)})
      --~ return id
    --~ end

    --~ -- Turret is connected, now get contents of adjacent pipes!
    --~ input = neighbours[1] and neighbours[1].get_fluid_contents()
    --~ --input = neighbours[1] and neighbours[1].fluidbox[1]
    --~ output = neighbours[2] and neighbours[2].get_fluid_contents()
    --~ -- Set vars to nil if they contain empty tables -- otherwise tests won't work!
    --~ if input and table_size(input) == 0 then input = nil end
    --~ if output and table_size(output) == 0 then output = nil end
    --~ -- input = (next(input) and input) or nil
    --~ -- output = (next(output) and output) or nil
--~ common.show("input", input)
--~ common.show("output", output)

    --~ -- Pipes are empty -- wait until they are filled up!
    --~ if not input and not output then
      --~ common.dprint("Leave early: %s is connected to empty pipes!", common.print_name_id(turret))
      --~ return id
    --~ -- Pipes contain some other fluid than steam or water
    --~ elseif (input and not (input.steam or input.water)) or
       --~ (output and not (output.steam or output.water)) then
      --~ common.dprint(
        --~ "Leave early: Neighbours of %s contain wrong fluid(s)! (Input: %s, output: %s)", {
          --~ common.print_name_id(turret),
          --~ ((input and input.steam and input.steam.name) or
          --~ (input and input.water and input.water.name)),
          --~ ((output and output.steam and output.steam.name) or
          --~ (output and output.water and output.water.name)) or "nil"
        --~ }
      --~ )
      --~ return id
    --~ -- Connected to 2 pipes with different fluids
    --~ elseif (input and output) and
            --~ ((input.steam and output.water) or
             --~ (input.water and output.steam)) then
      --~ common.dprint(
        --~ "Leave early: Neighbours of %s contain different fluids! (Input: %s, output: %s)", {
          --~ common.print_name_id(turret),
          --~ (input and input.steam and "steam" or input and input.water and "water"),
          --~ (output and output.steam and "steam" or output and output.water and "water")
        --~ }
      --~ )
      --~ return id
    --~ end
    --~ -- Connected to 2 pipes filled with same fluid as turret
    --~ -- (Both pipes contain the same fluid, so we need to check just one pipe!)
    --~ if (input and output) and (
            --~ (turret.name == common.steam_turret_name and t_fluid.steam and input.steam) or
            --~ (turret.name == common.water_turret_name and t_fluid.water and input.water)
          --~ ) then
      --~ common.dprint("Leave early: %s is connected to %s", {
        --~ common.print_name_id(turret),
        --~ (input.steam and "steam" or input.water and "water")
      --~ })
      --~ return id
    --~ -- Connected to 1 pipe filled with same fluid as turret
    --~ elseif (
              --~ (input and input.steam and turret.name == common.steam_turret_name) or
              --~ (input and input.water and turret.name == common.water_turret_name)
            --~ ) or (
              --~ (output and output.steam and turret.name == common.steam_turret_name) or
              --~ (output and output.water and turret.name == common.water_turret_name)
            --~ ) then
      --~ common.dprint(
        --~ "Leave early: %s is connected to %s", {
          --~ common.print_name_id(turret),
          --~ (
            --~ (input and input.steam and "steam") or
            --~ (input and input.water and "water") or
            --~ (output and output.steam and "steam") or
            --~ (output and output.water and "water")
          --~ )
        --~ }
      --~ )
      --~ return id
    --~ end


    --~ ------------------------------------------------------------------------------------
    --~ --                       We should replace the old turret!                        --
    --~ ------------------------------------------------------------------------------------
    --~ -- Replace steam turret?
    --~ if  turret.name == common.steam_turret_name and
        --~ (input and input.water) or
        --~ (output and output.water) then
      --~ new_turret = common.water_turret_name
    --~ -- Replace water turret?
    --~ elseif turret.name == common.water_turret_name and
           --~ (input and input.steam) or
           --~ (output and output.steam) then
      --~ new_turret = common.steam_turret_name
    --~ -- This should never be called!
    --~ else
      --~ error(string.format("Something is wrong with %s!\nInput: %s\nOutput: %s",
                            --~ turret and turret.name or "unknown turret", input, output))
    --~ end
    --~ common.dprint("Replacing %s with %s!", { common.print_name_id(turret), new_turret })
--~ common.dprint("input: %s\toutput: %s", {input or "none", output or "none"})


    --~ -- Swap entities
    --~ if new_turret then
      -- Store fluid from connecting pipes. We'll need to insert it into the new turret!
      --~ --t_fluid = (input and neighbours[1].fluidbox[1]) or
                --~ -- (output and neighbours[2].fluidbox[1])

      --~ local properties = {
        --~ ["surface"] = turret.surface,
        --~ ["position"] = turret.position,
        --~ ["direction"] = turret.direction,
        --~ ["force"] = turret.force,
        --~ ["target"] = turret.shooting_target,
        --~ ["damage_dealt"] = turret.damage_dealt,
        --~ ["kills"] = turret.kills,
      --~ }
      --~ -- common.show("Stored properties of " .. common.print_name_id(turret), properties)
      --~ -- Remove old turret
      --~ turret.destroy({ raise_destroy = false })
      --~ -- Create new turret
      --~ local t = properties.surface.create_entity{
        --~ name = new_turret,
        --~ position = properties.position,
        --~ direction = properties.direction,
        --~ force = properties.force,
        --~ target = properties.shooting_target,
      --~ }

      --~ if t then
        --~ common.show("Created", common.print_name_id(t))
        --~ -- Register new turret (new turrets will keep "tick" and area of the turret they replaced)
        --~ storage.WT_turrets[t.unit_number] = {
          --~ ["entity"] = t,
          --~ ["tick"] = storage.WT_turrets[id].tick,
          --~ ["area"] = storage.WT_turrets[id].area,
          --~ ["min_range"] = storage.WT_turrets[id].min_range,
          --~ ["range"] = storage.WT_turrets[id].range,
          --~ ["id"] = t.unit_number,
        --~ }
        --~ -- Transfer damage dealt by this turret and number of kills to new turret
        --~ storage.WT_turrets[t.unit_number].entity.damage_dealt = properties.damage_dealt
        --~ storage.WT_turrets[t.unit_number].entity.kills = properties.kills
  --~ common.dprint("storage.WT_turrets[%g].entity: %s",
                --~ { t.unit_number, storage.WT_turrets[t.unit_number].entity })
--~ common.dprint("New contents of %s. 1: %s\t2: %s", {common.print_name_id(t), t.fluidbox and t.fluidbox[1] or "empty", t.fluidbox and t.fluidbox[2] or "empty"})
      --~ else
        --~ error("Something bad happened: Couldn't create " .. new_turret .. "!")
      --~ end

      --~ turret = storage.WT_turrets[t.unit_number].entity

    --~ end
    --~ common.dprint("Contents of %s: %s", { common.print_name_id(turret), turret.fluidbox } )
    --~ common.dprint("End of function swap_turrets(%s).", { id })

    --~ return turret.unit_number
  --~ end


  --~ ------------------------------------------------------------------------------------
  --~ --                  Search for fire
  --~ ------------------------------------------------------------------------------------
  --~ common.find_fire = function(turret)
    --~ common.dprint("Entered function find_fire(%s) on tick %g.",
                  --~ { common.print_name_id(turret), game.tick })

    --~ -- Check argument
    --~ if not (turret and turret.valid and storage.WT_turrets[turret.unit_number]) then
      --~ error("Wrong arguments for function find_fire(turret):\nTurret is not valid!\n")
    --~ end

    --~ local ret

    --~ -- Determine search area in the direction the turret is facing
    --~ local area = storage.WT_turrets[turret.unit_number].area or
                  --~ common.get_turret_area(turret)
--~ common.show("Turret area", area)
    --~ local x_min = area.left_top.x or area.left_top[1]
    --~ local y_min = area.left_top.y or area.left_top[2]
    --~ local x_max = area.right_bottom.x or area.right_bottom[1]
    --~ local y_max = area.right_bottom.y or area.right_bottom[2]
--~ common.show("storage.dummy_positions", storage.dummy_positions)
    --~ for x, y in pairs(storage.dummy_positions) do
--~ common.dprint("x: %s\tx_min: %s\tx_max: %s", {x, x_min, x_max})
      --~ if x >= x_min and x <= x_max then
--~ common.dprint("x is valid -- checking y!")
        --~ for y, dummy_id in pairs(y) do
--~ common.dprint("y: %s\ty_min: %s\ty_max: %s", {y, y_min, y_max})
          --~ if y >= y_min and y <= y_max and common.can_shoot(turret, {x, y}) then
            --~ ret = dummy_id
            --~ break
          --~ end
        --~ end
      --~ end
      --~ if ret then
        --~ break
      --~ end
    --~ end

    --~ common.dprint("End of function find_fire(%s) on tick %g. (Return: %s)", {
      --~ common.print_name_id(turret),
      --~ game.tick, ret or "nil"
    --~ })
    --~ return ret
  --~ end

  ------------------------------------------------------------------------------------
  --                                       EOF                                      --
  ------------------------------------------------------------------------------------
  return common
end
