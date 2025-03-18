local prototypes = require("prototypes_with_health")
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
                                      { r = 0.961, g = 0.181, b = 0.181, a = 1}

    -- Modifier for pressure (affects stream animation speed, damage, and fluid consumption)
    common.water_turret_pressure = settings.startup["WT-water-turret-pressure"].value
    common.extinguisher_turret_pressure = settings.startup["WT-extinguisher-turret-pressure"].value

    -- As long as we don't have an extinguisher fluid, this setting will be disabled and we
    -- use a default value as fallback
    --~ common.extinguisher_damage_modifier = settings.startup["WT-extinguisher-damage-modifier"].value
    common.extinguisher_damage_modifier =
        settings.startup["WT-extinguisher-damage-modifier"] and
        settings.startup["WT-extinguisher-damage-modifier"].value or 5
    --~ common.waterturret_priority = settings.startup["WT-waterturret_preferred_target"].value
    -- Slowdown factor
    common.slowdown_factor = settings.startup["WT-extinguisher-damage-modifier"].value / 100
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
  end


  -- Set mod name and base path
  common.mod_name = common.mod_name or "WaterTurret"
  common.mod_root = "__" .. common.mod_name .. "__/"


  -- Turret type and names
  common.turret_type = "fluid-turret"
  common.steam_turret_name = "WT-steam-turret"
  common.water_turret_name = "WT-water-turret"
  common.extinguisher_turret_name = "WT-fire-ex-turret"
  -- Searchable list of turret names
  common.turret_names = {
    [common.steam_turret_name] = true,
    [common.water_turret_name] = true,
    [common.extinguisher_turret_name] = true,
  }
  --~ common.turret_list = common.make_name_list(common.turret_names)

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

  -- Sticker names
  common.slowdown_sticker_name = "WaterTurrets_slowdown_sticker"

  -- Dummies
  common.dummy_type = "simple-entity-with-force"
  common.dummy_force = "WT-fire-dummy"

  common.acid_dummy_name = "acid-dummy"
  common.fire_dummy_name = "fire-dummy"

  -- Searchable list of dummy names
  common.dummy_types = {
    [common.acid_dummy_name] = true,
    [common.fire_dummy_name] = true,
  }
  common.dummy_list = common.make_name_list(common.dummy_types)

  -- Animations rendered on dummy position
  common.dummy_animation_name = "WT-fire-dummy-animation"


   -- This are functions that return an array!
  common.enemies = prototypes.attack
  common.enemy_healing = prototypes.healing
--~ log("enemy_healing: " .. serpent.block(common.enemy_healing))
  -- Searchable list of acid names
  common.acid_types = {}

  -- Just define these to avoid tests not working because of a typo!
  common.spawner_type = "unit-spawner"
  common.worm_type = "turret"
  common.artillery_type = "artillery-turret"

  ------------------------------------------------------------------------------------
  --                                   Debugging                                    --
  ------------------------------------------------------------------------------------
  --~ common.debug_in_log = false
  common.debug_in_game = false
  -- Hide "mods" from eradicator's "Find (undefined) local vars in global context" code
  -- at the end of the control file.
  --~ if  (game and game.active_mods["_debug"]) or
      --~ (not game and mods and mods["_debug"]) or
      --~ common.debug_to_log_setting then
    --~ common.debug_in_log = true
  --~ end
  if common.debug_to_log_setting then
    common.debug_in_log = true
  end

  -- Output debugging text
  common.dprint = function(msg, tab, ...)
    local args = {}
--~ log("msg: " .. msg .. "\ttab: " .. serpent.line(tab))
    -- Use serpent.line instead of serpent.block if this is true!
    local line = ... and
                  (string.lower(...) == "line" or string.lower(...) == "l") and
                  true or false

    if common.debug_in_log or common.debug_in_game then
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
      id =  (entity.type == "sticker" and entity.type) or
            --~ (entity.type == "character" and entity.index) or
            entity.unit_number or entity.type

      name = entity.name
    end

    --~ return name .. " (" .. tostring(id) .. ")"
    return string.format("%s (%s)", name, id)
  end

  -- Print "entityname"
  common.print_name = function(entity)
    return entity and entity.valid and entity.name or ""
  end

  ------------------------------------------------------------------------------------
  --                                     Recipe                                     --
  ------------------------------------------------------------------------------------
  common.compile_recipe = function(recipe, recipe_data_normal, recipe_data_expensive)

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
      for k, v in pairs(recipe_data_expensive) do
        recipe.expensive[k] = v
      end
    -- If recipe_data_expensive doesn't exist, double the amount of all ingredients
    else
--~ common.dprint ("expensive ingredients: %s", recipe.expensive.ingredients)
      for k, v in pairs(recipe.expensive.ingredients) do
        v.amount = v.amount * 2
      end
    end

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
    common.dprint("Entered function is_WT_turret(%s).", {common.print_name_id(turret)})

    return (turret and turret.valid) and
            (turret.type and turret.type == common.turret_type) and
            (turret.name and common.turret_names[turret.name]) and
            true or false
  end

  -- Check for distance >= min_range  (returns true or false)
  common.is_in_range = function(turret, target)
    common.dprint("Entered function is_in_range(%s, %s).",
                  { common.print_name(turret), common.print_name(target) })

    -- Check arguments
    if not (turret and turret.valid and target and target.valid) then
      error("Wrong arguments for function is_in_range(" ..
            tostring(turret) .. ", " .. tostring(target) .. ")!")
    end

    -- Get distance
    local tu, ta = turret.position, target.position
    local x, y = tu.x - ta.x, tu.y - ta.y
    local distance = math.sqrt(x*x + y*y)

    -- We searched a radius of max range, so we only need to check for min_range here!
    common.dprint("End of function is_in_range(%s, %s).",
                  { common.print_name(turret), common.print_name(target) })
    return (distance >= global.WT_turrets[turret.unit_number].min_range)
  end

  ------------------------------------------------------------------------------------
  --         Get the rectangular area in the direction the turret is facing         --
  ------------------------------------------------------------------------------------
  common.get_turret_area = function(turret)
    common.dprint("Entered function get_turret_area(%s).", {common.print_name_id(turret)})

    if not common.is_WT_turret(turret) then
      error("Wrong argument -- not a valid turret: " .. serpent.block(turret))
    end

    local x, y = turret.position.x, turret.position.y
    --~ common.show("x", x)
    --~ common.show("y", y)
    --~ common.show("direction", turret.direction)
    local left_top, right_bottom
    local range = global.WT_turrets[turret.unit_number] and
                    global.WT_turrets[turret.unit_number].range or
                    turret.prototype.attack_parameters.range

    -- Turret facing North
    if turret.direction == defines.direction.north then
      left_top = { x - range, y - range }
      right_bottom = { x + range, y }
    -- Turret facing South
    elseif turret.direction == defines.direction.south then
      left_top = {x - range, y}
      right_bottom = {x + range, y + range}
    -- Turret facing East
    elseif turret.direction == defines.direction.east then
      left_top = {x, y - range}
      right_bottom = {x + range, y + range}
    -- Turret facing West
    elseif turret.direction == defines.direction.west then
      left_top = {x - range, y - range}
      right_bottom = {x, y + range}
    -- This should never be reached!
    else
      --~ error("Something unexpected has happened: " .. common.print_name_id(turret) ..
            --~ " has direction " .. tostring(turret.direction) ..
            --~ ", which is not a cardinal direction.")
      error(string.format(
        "Something unexpected has happened: %s has direction %s, which is not a cardinal direction.", common.print_name_id(turret), turret.direction)
      )
    end

    common.dprint("End of function get_turret_area(%s).", {common.print_name_id(turret)})
    --~ if global.WT_turrets[turret.unit_number] then
      --~ if global.WT_turrets[turret.unit_number].render_area then
        --~ rendering.destroy(global.WT_turrets[turret.unit_number].render_area)
      --~ end
      --~ global.WT_turrets[turret.unit_number].render_area = rendering.draw_rectangle{left_top = left_top, right_bottom = right_bottom, color = {r = 0.5, a = 0.001}, filled = true, surface = turret.surface}
      --~ rendering.draw_circle{color= {g = 0.5, a = 0.001}, radius = range, filled = true, target = turret.position, surface = turret.surface}
    --~ end

    return { left_top = left_top, right_bottom = right_bottom }
  end


  ------------------------------------------------------------------------------------
  --        Exchange steam and water turrets if fluidbox contains wrong ammo        --
  --        (Returns nil for invalid turrets, or id (unit_number) of turret)        --
  ------------------------------------------------------------------------------------
  common.swap_turrets = function(id)
    common.dprint("Entered function swap_turrets(%s).", {id})

    ------------------------------------------------------------------------------------
    --                               Bail out on errors                               --
    ------------------------------------------------------------------------------------
    -- Invalid argument
    if (not id) or (type(id) ~= "number") then
      error("\"" .. tostring(id) .. "\" is not a valid turret id!")
    -- No turret stored with this ID
    elseif not global.WT_turrets[id] then
      error("No turret with id " .. tostring(id) .. " has been registered!")
    -- Invalid turret
    elseif not global.WT_turrets[id].entity.valid then
      global.WT_turrets[id] = nil
      common.dprint("Removed expired id %s from list of registered turrets.", {id})
      return nil
    end

    ------------------------------------------------------------------------------------
    --                                Local definitions                               --
    ------------------------------------------------------------------------------------

--~ common.dprint ("Looking for turret with id %s.", {id})
--~ common.dprint("global.WT_turrets[%g]: %s", { id, global.WT_turrets[id] } )

    local turret = global.WT_turrets[id].entity
    local new_turret = nil
    local input = nil
    local output = nil
    local neighbours = turret.neighbours and turret.neighbours[1] or nil
    local t_fluid = turret.get_fluid_contents()
    -- Set neighbours to nil if it's an empty table -- otherwise tests won't work!
    if neighbours and table_size(neighbours) == 0 then neighbours = nil end

common.dprint ("Neighbours of %s: %s ", {turret.name, neighbours and neighbours.name or "none"})

common.dprint("t_fluid: %s", t_fluid)
common.dprint("t_fluid.steam and turret.name == \"%s\": %s", {common.water_turret_name, t_fluid.steam and turret.name == common.water_turret_name and true or false})
common.dprint("t_fluid.water and turret.name == \"%s\": %s", {common.steam_turret_name, t_fluid.water and turret.name == common.steam_turret_name and true or false})
    ------------------------------------------------------------------------------------
    --                        Leave early if everything is OK                         --
    ------------------------------------------------------------------------------------
    -- Turret is not connected to a pipe and doesn't contain fluid -- wait until it is
    -- hooked up and useful!
--~ common.show("turret.get_fluid_contents()", turret.get_fluid_contents())
    if not neighbours then
      common.dprint("Leave early: %s is not hooked up!", {common.print_name_id(turret)})
      return id
    end

    -- Turret is connected, now get contents of adjacent pipes!
    input = neighbours[1] and neighbours[1].get_fluid_contents()
    --~ input = neighbours[1] and neighbours[1].fluidbox[1]
    output = neighbours[2] and neighbours[2].get_fluid_contents()
    -- Set vars to nil if they contain empty tables -- otherwise tests won't work!
    if input and table_size(input) == 0 then input = nil end
    if output and table_size(output) == 0 then output = nil end
    --~ input = (next(input) and input) or nil
    --~ output = (next(output) and output) or nil
common.show("input", input)
common.show("output", output)

    -- Pipes are empty -- wait until they are filled up!
    if not input and not output then
      common.dprint("Leave early: %s is connected to empty pipes!", common.print_name_id(turret))
      return id
    -- Pipes contain some other fluid than steam or water
    elseif (input and not (input.steam or input.water)) or
       (output and not (output.steam or output.water)) then
      common.dprint(
        "Leave early: Neighbours of %s contain wrong fluid(s)! (Input: %s, output: %s)", {
          common.print_name_id(turret),
          ((input and input.steam and input.steam.name) or
          (input and input.water and input.water.name)),
          ((output and output.steam and output.steam.name) or
          (output and output.water and output.water.name)) or "nil"
        }
      )
      return id
    -- Connected to 2 pipes with different fluids
    elseif (input and output) and
            ((input.steam and output.water) or
             (input.water and output.steam)) then
      common.dprint(
        "Leave early: Neighbours of %s contain different fluids! (Input: %s, output: %s)", {
          common.print_name_id(turret),
          (input and input.steam and "steam" or input and input.water and "water"),
          (output and output.steam and "steam" or output and output.water and "water")
        }
      )
      return id
    end
    -- Connected to 2 pipes filled with same fluid as turret
    -- (Both pipes contain the same fluid, so we need to check just one pipe!)
    if (input and output) and (
            (turret.name == common.steam_turret_name and t_fluid.steam and input.steam) or
            (turret.name == common.water_turret_name and t_fluid.water and input.water)
          ) then
      common.dprint("Leave early: %s is connected to %s", {
        common.print_name_id(turret),
        (input.steam and "steam" or input.water and "water")
      })
      return id
    -- Connected to 1 pipe filled with same fluid as turret
    elseif (
              (input and input.steam and turret.name == common.steam_turret_name) or
              (input and input.water and turret.name == common.water_turret_name)
            ) or (
              (output and output.steam and turret.name == common.steam_turret_name) or
              (output and output.water and turret.name == common.water_turret_name)
            ) then
      common.dprint(
        "Leave early: %s is connected to %s", {
          common.print_name_id(turret),
          (
            (input and input.steam and "steam") or
            (input and input.water and "water") or
            (output and output.steam and "steam") or
            (output and output.water and "water")
          )
        }
      )
      return id
    end


    ------------------------------------------------------------------------------------
    --                       We should replace the old turret!                        --
    ------------------------------------------------------------------------------------
    -- Replace steam turret?
    if  turret.name == common.steam_turret_name and
        (input and input.water) or
        (output and output.water) then
      new_turret = common.water_turret_name
    -- Replace water turret?
    elseif turret.name == common.water_turret_name and
           (input and input.steam) or
           (output and output.steam) then
      new_turret = common.steam_turret_name
    -- This should never be called!
    else
      error(string.format("Something is wrong with %s!\nInput: %s\nOutput: %s",
                            turret and turret.name or "unknown turret", input, output))
    end
    common.dprint("Replacing %s with %s!", { common.print_name_id(turret), new_turret })
common.dprint("input: %s\toutput: %s", {input or "none", output or "none"})


    -- Swap entities
    if new_turret then
      --~ -- Store fluid from connecting pipes. We'll need to insert it into the new turret!
      --~ t_fluid = (input and neighbours[1].fluidbox[1]) or
                --~ (output and neighbours[2].fluidbox[1])

      local properties = {
        ["surface"] = turret.surface,
        ["position"] = turret.position,
        ["direction"] = turret.direction,
        ["force"] = turret.force,
        ["target"] = turret.shooting_target,
        ["damage_dealt"] = turret.damage_dealt,
        ["kills"] = turret.kills,
      }
      --~ common.show("Stored properties of " .. common.print_name_id(turret), properties)
      -- Remove old turret
      turret.destroy({ raise_destroy = false })
      -- Create new turret
      local t = properties.surface.create_entity{
        name = new_turret,
        position = properties.position,
        direction = properties.direction,
        force = properties.force,
        target = properties.shooting_target,
      }

      if t then
        common.show("Created", common.print_name_id(t))
        -- Register new turret (new turrets will keep "tick" and area of the turret they replaced)
        global.WT_turrets[t.unit_number] = {
          ["entity"] = t,
          ["tick"] = global.WT_turrets[id].tick,
          ["area"] = global.WT_turrets[id].area,
          ["min_range"] = global.WT_turrets[id].min_range,
          ["range"] = global.WT_turrets[id].range,
          ["id"] = t.unit_number,
        }
        -- Transfer damage dealt by this turret and number of kills to new turret
        global.WT_turrets[t.unit_number].entity.damage_dealt = properties.damage_dealt
        global.WT_turrets[t.unit_number].entity.kills = properties.kills
  common.dprint("global.WT_turrets[%g].entity: %s",
                { t.unit_number, global.WT_turrets[t.unit_number].entity })
common.dprint("New contents of %s. 1: %s\t2: %s", {common.print_name_id(t), t.fluidbox and t.fluidbox[1] or "empty", t.fluidbox and t.fluidbox[2] or "empty"})
      else
        error("Something bad happened: Couldn't create " .. new_turret .. "!")
      end

      turret = global.WT_turrets[t.unit_number].entity

    end
    common.dprint("Contents of %s: %s", { common.print_name_id(turret), turret.fluidbox } )
    common.dprint("End of function swap_turrets(%s).", { id })

    return turret.unit_number
  end


  ------------------------------------------------------------------------------------
  --                  Search for fire
  ------------------------------------------------------------------------------------
  common.find_fire = function(turret)
    common.dprint("Entered function find_fire(%s) on tick %g.",
                  { common.print_name_id(turret), game.tick })

    -- Check argument
    if not (turret and turret.valid) then
      error("Wrong arguments for function find_fire(turret):\nTurret is not valid!\n")
    end

    local fires

    -- Determine search area in the direction the turret is facing
    local area = global.WT_turrets[turret.unit_number].area or
                  common.get_turret_area(turret)
    local dummy, dummy_id, fire_id

    -- Do we clean up acid splashes? Then we should check if the turret shoots
    -- steam! We want to ignore other fires in that case.
    if turret.name == common.steam_turret_name then
    --~ common.dprint("name: %s\tposition: %s\tradius: %s", {
      --~ global.acids,
      --~ turret.position,
      --~ (global.WT_turrets[turret.unit_number].range or turret.prototype.attack_parameters.range)
    --~ })
      fires = table_size(global.acids) > 0 and turret.surface.find_entities_filtered({
        type = "fire",
        name = global.acids,
        position = turret.position,
        radius = global.WT_turrets[turret.unit_number].range or
                  turret.prototype.attack_parameters.range
      }) or {}

    -- Get all fires around turret position (radius: turret range)
    else
      fires = turret.surface.find_entities_filtered{
        type = "fire",
        position = turret.position,
        radius = global.WT_turrets[turret.unit_number].range or
                  turret.prototype.attack_parameters.range
      }
    end

    -- Find fires in direction the turret is facing
--~ common.show("area", area)
    --~ local extinguisher_target
    for f, fire in ipairs(fires) do
--~ common.dprint("%g: %s\tposition: %s", { f, fire.name, fire.position })
      if not global.ignore_fires[fire.name] and
          (turret.name == common.extinguisher_turret_name and
            common.is_in_range(turret, fire)) or
          (math2d.bounding_box.contains_point(area, fire.position) and
            common.is_in_range(turret, fire)) then
common.dprint("Fire is in area and in range!")

        -- Generate ID for fire (If the same entity is registered multiple times,
        -- it will always get the same ID.)
        fire_id = script.register_on_entity_destroyed(fire)
  --~ common.show("fire_id", fire_id)
        -- Has that fire already been registered for another turret?
        if global.fires[fire_id] then
          dummy = global.fires[fire_id].dummy_entity
        -- New fire -- create dummy!
        else
          local name = (common.acid_types[fire.name]) and
                        common.acid_dummy_name or common.fire_dummy_name
          dummy = fire.surface.create_entity({
            name = name,
            position = fire.position,
            force = common.dummy_force,
          })

          if name == common.fire_dummy_name then
            rendering.draw_animation({
              animation = common.dummy_animation_name,
              target = dummy,
              surface = dummy.surface,
              render_layer = "ground-patch"
            })
          end
        end

        if dummy and dummy.valid then
          dummy_id = dummy.unit_number
          common.show("Created dummy", dummy_id)
          local fire_data = {
            dummy_entity = dummy,
            dummy_id = dummy_id,
            fire_entity = fire,
            fire_id = fire_id,
          }
          global.fire_dummies[dummy_id] = fire_data
          global.fires[fire_id] = fire_data

          -- We don't store fires with steam turrets!
          --~ if not (common.clean_acid_splashes) then
          if turret.name ~= common.steam_turret_name then
            global.WT_turrets[turret.unit_number].fire_dummies[dummy_id] = fire_data
            global.WT_turrets[turret.unit_number].fires[fire_id] = fire_data
          end
          --~ extinguisher_target = dummy
        end
      end
    end
--~ common.show(" (turret.name == common.extinguisher_turret_name) and extinguisher_target",  (turret.name == common.extinguisher_turret_name) and extinguisher_target)
--~ common.show("extinguisher_target: ", extinguisher_target)
    --~ if (turret.name == common.extinguisher_turret_name) and extinguisher_target then
--~ common.dprint("Setting target for extinguisher turret!")
      --~ turret.shooting_target = extinguisher_target
    --~ end
--~ common.dprint("global.fire_dummies %s", { global.fire_dummies or {} })
--~ common.dprint("global.fires %s", { global.fires or {} })
--~ common.dprint("global.WT_turrets[%g].fire_dummies: %s", {
  --~ turret.unit_number,
  --~ global.WT_turrets[turret.unit_number].fire_dummies or {}
--~ })
--~ common.dprint("global.WT_turrets[%g].fires: %s", {
  --~ turret.unit_number,
  --~ global.WT_turrets[turret.unit_number].fires or {}
--~ })

    common.dprint("End of function find_fire(%s) on tick %g.", {
      common.print_name_id(turret),
      game.tick
    })
  end

  ------------------------------------------------------------------------------------
  --                                       EOF                                      --
  ------------------------------------------------------------------------------------
  return common
end
