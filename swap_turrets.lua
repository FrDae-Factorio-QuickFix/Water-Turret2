local WT = require("common")()

local input, output
--~ local neighbours, t_fluid

local swap_turrets = {}

local map = {
  [WT.water_turret_name] = {WT.steam_turret_name, "water", "steam"},
  [WT.steam_turret_name] = {WT.water_turret_name, "steam", "water"},
  [WT.extinguisher_turret_name] = {
    WT.extinguisher_turret_water_name, WT.fire_ex_fluid, "water"
  },
  [WT.extinguisher_turret_water_name] = {
    WT.extinguisher_turret_name, "water", WT.fire_ex_fluid
  },
}

--~ swap_turrets.profiler = swap_turrets.profiler or game and game.create_profiler()

------------------------------------------------------------------------------------
--                  Check if turret is hooked up to currect fluid                 --
------------------------------------------------------------------------------------
swap_turrets.can_return = function(turret, name_a, name_b, fluid_a, fluid_b)
WT.dprint("Entered function can_return(%s).", {WT.print_name_id(turret)})

local errmsg
  turret = (type(turret) == "number" and
              storage.WT_turrets[turret] and
              storage.WT_turrets[turret].entity) or turret
  --~ if not WT.is_WT_turret(turret) then
    --~ errmsg = string.format("%s is not a valid turret!", turret and turret.name or "nil")
  --~ end
  --~ name_a = (type(name_a) == "string") and WT.turret_names[name_a] and name_a
  --~ if not name_a then
    --~ errmsg = string.format("%s is not a valid turret name!", name_a or "nil")
  --~ end
  --~ name_b = (type(name_b) == "string") and WT.turret_names[name_b] and name_b
  --~ if not name_b then
    --~ errmsg = string.format("%s is not a valid turret name!", name_b or "nil")
  --~ end
  --~ fluid_a = (type(fluid_a) == "string") and WT.fluid_names[fluid_a] and fluid_a
  --~ if not fluid_a then
    --~ errmsg = string.format("%s is not a valid fluid name!", fluid_a or "nil")
  --~ end
  --~ fluid_b = (type(fluid_b) == "string") and WT.fluid_names[fluid_b] and fluid_b
  --~ if not fluid_b then
    --~ errmsg = string.format("%s is not a valid fluid name!", fluid_b or "nil")
  --~ end
  --~ name_a = name_a and WT.turret_names[name_a] and name_a
  if not WT.is_WT_turret(turret) then
    errmsg = {"%s is not a valid turret!", turret and turret.name or "nil"}
  end
  if not name_a and WT.turret_names[name_a] then
    errmsg = {"%s is not a valid turret name!", name_a or "nil"}
  end
  --~ name_b = name_b and WT.turret_names[name_b]
  if not name_b and WT.turret_names[name_b] then
    errmsg = {"%s is not a valid turret name!", name_b or "nil"}
  end
  --~ fluid_a = (type(fluid_a) == "string") and WT.fluid_names[fluid_a] and fluid_a
  if not fluid_a and WT.fluid_names[fluid_a] then
    errmsg = {"%s is not a valid fluid name!", fluid_a or "nil"}
  end
  --~ fluid_b = (type(fluid_b) == "string") and fluid_b
  if not fluid_b  and WT.fluid_names[fluid_b] then
    errmsg = {"%s is not a valid fluid name!", fluid_b or "nil"}
  end

  if errmsg then
    error(string.format(errmsg[1], errmsg[2]))
  end

  local ret = false
  local msg
  input = nil
  output = nil
  local neighbours = turret.neighbours and turret.neighbours[1] or nil
  local t_fluid = turret.get_fluid_contents()

  -- Set neighbours to nil if it's an empty table -- otherwise tests won't work!
  if neighbours and not next(neighbours) then neighbours = nil end


  ------------------------------------------------------------------------------------
  --                        Leave early if everything is OK                         --
  ------------------------------------------------------------------------------------
  -- Turret is not connected to a pipe and doesn't contain fluid -- wait until it is
  -- hooked up and useful!
--~ WT.show("turret.get_fluid_contents()", turret.get_fluid_contents())
  if not neighbours then
    --~ WT.dprint("Leave early: %s is not hooked up!", {WT.print_name_id(turret)})
    msg =  {"Leave early: %s is not hooked up!", WT.print_name_id(turret)}
    ret = true
    return ret, msg
  end

  -- Turret is connected, now get contents of adjacent pipes!
  input = neighbours[1] and neighbours[1].get_fluid_contents()
  --~ input = neighbours[1] and neighbours[1].fluidbox[1]
  output = neighbours[2] and neighbours[2].get_fluid_contents()
  -- Set vars to nil if they contain empty tables -- otherwise tests won't work!
  if input and not (next(input)) then input = nil end
  if output and not (next(output)) then output = nil end
--~ WT.show("input", input)
--~ WT.show("output", output)

  -- Pipes are empty -- wait until they are filled up!
  if not input and not output then
    --~ WT.dprint("Leave early: %s is connected to empty pipes!", WT.print_name_id(turret))
    msg = {"Leave early: %s is connected to empty pipes!", WT.print_name_id(turret)}
    ret = true

  -- Pipes contain some other fluid than needed
  elseif (input and not (input[fluid_a] or input[fluid_b])) or
     (output and not (output[fluid_a] or output[fluid_b])) then
    msg = {
      "Leave early: Neighbours of %s contain wrong fluid(s)! (Input: %s, output: %s)",
        {
        WT.print_name_id(turret),
        ((input and input[fluid_a] and input[fluid_a].name) or
        (input and input[fluid_b] and input[fluid_b].name)),
        ((output and output[fluid_a] and output[fluid_a].name) or
        (output and output[fluid_b] and output[fluid_b].name)) or "nil"
      }
    }
    ret = true
  -- Connected to 2 pipes with different fluids
  elseif (input and output) and
          ((input[fluid_a] and output[fluid_b]) or
           (input[fluid_b] and output[fluid_a])) then
    msg = {
      "Leave early: Neighbours of %s contain different fluids! (Input: %s, output: %s)",
        {
        WT.print_name_id(turret),
        (input and (input[fluid_a] and fluid_a) or (input[fluid_b] and fluid_b)),
        (output and (output[fluid_a] and fluid_a) or (output[fluid_b] and fluid_b))
      }
    }
    ret = true
  -- Connected to 2 pipes filled with same fluid as turret
  -- (Both pipes contain the same fluid, so we need to check just one pipe!)
  --~ if (input and output) and (
  elseif (input and output) and (
          (turret.name == name_a and t_fluid[fluid_a] and input[fluid_a]) or
          (turret.name == name_b and t_fluid[fluid_b] and input[fluid_b])
        ) then
    msg = {
        "Leave early: %s is connected to %s",
        {WT.print_name_id(turret), (input[fluid_a] and fluid_a) or (input[fluid_b] and fluid_b)}
    }
    ret = true
  -- Connected to 1 pipe filled with same fluid as turret
  elseif (
            (input and input[fluid_a] and turret.name == name_a) or
            (input and input[fluid_b] and turret.name == name_b)
          ) or (
            (output and output[fluid_a] and turret.name == name_a) or
            (output and output[fluid_b] and turret.name == name_b)
          ) then
    msg = {
      "Leave early: %s is connected to %s",
        {
        WT.print_name_id(turret),
        (
          (input and input[fluid_a] and fluid_a) or
          (input and input[fluid_b] and fluid_b) or
          (output and output[fluid_a] and fluid_a) or
          (output and output[fluid_b] and fluid_b)
        )
      }
    }
    ret = true
  end

  WT.dprint("End of function can_return(%s). (Return: %s)",
                  {WT.print_name_id(turret), ret})

  return ret, msg
end




------------------------------------------------------------------------------------
--        Exchange steam and water turrets if fluidbox contains wrong ammo        --
--        (Returns nil for invalid turrets, or id (unit_number) of turret)        --
------------------------------------------------------------------------------------
swap_turrets.swap_turrets = function(id)

--~ swap_turrets.profiler = swap_turrets.profiler or game and game.create_profiler()
--~ if swap_turrets.profiler then swap_turrets.profiler.reset() end

  WT.dprint("Entered function swap_turrets(%s).", {id})

  ------------------------------------------------------------------------------------
  --                               Bail out on errors                               --
  ------------------------------------------------------------------------------------
  -- Invalid argument
  --~ if (not id) or (type(id) ~= "number") then
    --~ error(string.format("%s is not a valid turret id!", id))
  --~ -- No turret stored with this ID
  --~ elseif not storage.WT_turrets[id] then
    --~ error(string.format("No turret with id %s has been registered!", id))
  --~ -- Invalid turret
  --~ elseif not storage.WT_turrets[id].entity.valid then
    --~ storage.WT_turrets[id] = nil
    --~ WT.dprint("Removed expired id %s from list of registered turrets.", {id})
    --~ return nil
  --~ end
  --~ id =  (type(id) == "number" and id) or (id and id.valid and id.unit_number) or
          --~ error(string.format("%s is not a valid turret id!", id))
  -- No turret stored with this ID
  if id then
    if not storage.WT_turrets[id] then
      error(string.format("No turret with id %s has been registered!", id))
    -- Invalid turret
    elseif not storage.WT_turrets[id].entity.valid then
      storage.WT_turrets[id] = nil
      WT.dprint("Removed expired id %s from list of registered turrets.", {id})
      return nil
    end
  end

  ------------------------------------------------------------------------------------
  --                                Local definitions                               --
  ------------------------------------------------------------------------------------

WT.dprint ("Looking for turret with id %s.", {id})
WT.dprint("storage.WT_turrets[%g]: %s", { id, storage.WT_turrets[id] } )

  local turret = storage.WT_turrets[id].entity
  local new_turret = nil

  ------------------------------------------------------------------------------------
  -- Leave early if turret is not hooked up or connected to the correct fluid
  local name_a, name_b, fluid_a, fluid_b
  --~ local map = {
    --~ [WT.water_turret_name] = {WT.steam_turret_name, "water", "steam"},
    --~ [WT.steam_turret_name] = {WT.water_turret_name, "steam", "water"},
    --~ [WT.extinguisher_turret_name] = {
      --~ WT.extinguisher_turret_water_name, WT.fire_ex_fluid, "water"
    --~ },
    --~ [WT.extinguisher_turret_water_name] = {
      --~ WT.extinguisher_turret_name, "water", WT.fire_ex_fluid
    --~ },
  --~ }
  local name = turret.name
  -- Arguments: turret, name_a, name_b, fluid_a, fluid_b
  local ret, msg = swap_turrets.can_return(turret, name, map[name][1], map[name][2], map[name][3])
  if ret then
    -- Leave with a message!
    WT.dprint(msg[1], msg[2])

    --~ if swap_turrets.profiler then
      --~ swap_turrets.profiler.stop()
    --~ log({"", "swap_turrets.profiler: ", swap_turrets.profiler})
    --~ end
    return id
  end


  ------------------------------------------------------------------------------------
  --                         We must replace the old turret!                        --
  ------------------------------------------------------------------------------------

  -- Get the new turret
  local tu = map[turret.name]

  if (input and input[tu[3]]) or (output and output[tu[3]]) then
    new_turret = tu[1]
  end


  if not new_turret then
    error(string.format("Something is wrong with %s!\nInput: %s\nOutput: %s",
                          turret and turret.name or "unknown turret", input, output))
  end
  WT.dprint("Replacing %s with %s!", { WT.print_name_id(turret), new_turret })
  WT.dprint("input: %s\toutput: %s", {input or "none", output or "none"})


  -- Swap entities
  local properties = {
    ["surface"] = turret.surface,
    ["position"] = turret.position,
    ["direction"] = turret.direction,
    ["force"] = turret.force,
    ["target"] = turret.shooting_target,
    ["damage_dealt"] = turret.damage_dealt,
    ["kills"] = turret.kills,
    ["quality"] = turret.quality
  }
  --~ WT.show("Stored properties of " .. WT.print_name_id(turret), properties)
  -- Remove old turret
  turret.destroy({ raise_destroy = false })
  -- Create new turret
  local t = properties.surface.create_entity{
    name = new_turret,
    position = properties.position,
    direction = properties.direction,
    force = properties.force,
    target = properties.shooting_target,
    quality = properties.quality
  }

  if t then
    WT.show("Created", WT.print_name_id(t))
    -- Register new turret (new turrets will keep "tick" and area of the turret they replaced)
    storage.WT_turrets[t.unit_number] = {
      ["entity"] = t,
      ["tick"] = storage.WT_turrets[id].tick,
      ["area"] = storage.WT_turrets[id].area,
      ["min_range"] = storage.WT_turrets[id].min_range,
      ["range"] = storage.WT_turrets[id].range,
      ["id"] = t.unit_number,
    }
    -- Transfer damage dealt by this turret and number of kills to new turret
    storage.WT_turrets[t.unit_number].entity.damage_dealt = properties.damage_dealt
    storage.WT_turrets[t.unit_number].entity.kills = properties.kills
WT.dprint("storage.WT_turrets[%g].entity: %s",
              { t.unit_number, storage.WT_turrets[t.unit_number].entity })
--WT.dprint("New contents of %s. 1: %s\t2: %s", {WT.print_name_id(t), t.fluidbox and t.fluidbox[1] or "empty", t.fluidbox and t.fluidbox[2] or "empty"})
  else
    error(string.format("Something bad happened: Couldn't create %s!", new_turret))
  end

  turret = storage.WT_turrets[t.unit_number].entity

  --~ end
  WT.dprint("Contents of %s: %s", { WT.print_name_id(turret), turret.fluidbox } )
  WT.dprint("End of function swap_turrets(%s).", { id })

  --~ if swap_turrets.profiler then
    --~ swap_turrets.profiler.stop()
  --~ log({"", "swap_turrets.profiler: ", swap_turrets.profiler})
  --~ end
  return turret.unit_number
end

return swap_turrets
