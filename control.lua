log("Entered control.lua now")
local WT = require("common")()

------------------------------------------------------------------------------------
--                               Fire extinguisher                                --
------------------------------------------------------------------------------------

-- Check for distance >= min_range  (returns true or false)
local function is_in_range(turret, target)
    WT.dprint("Entered function is_in_range(" .. WT.print_name(turret) .. ", " ..
            WT.print_name(target) .. ").")

    -- Check arguments
    local args = {}
    local msg = nil

    if not (turret and turret.valid) then args[#args +1] = "Turret" end
    if not (target and target.valid) then args[#args +1] = "Target" end
    for _, arg in pairs(args) do msg = msg .. arg .. " is not valid!\n" end
    if msg then error("Wrong arguments for function is_in_range(turret, target):\n" .. msg) end

    -- Get distance
    local tu, ta = turret.position, target.position
    local x, y = tu.x - ta.x, tu.y - ta.y
    local distance = math.sqrt(x*x + y*y)

    WT.show("distance", distance)
    -- We searched a radius of max range, so we only need to check for min_range here!
    WT.dprint("End of function is_in_range(" .. WT.print_name(turret) .. ", " ..
            WT.print_name(target) .. ").")
    return (distance >= turret.prototype.attack_parameters.min_range) and true or false
end


-- Check if target belongs to us (own force, friends, allies) or is an enemy
-- (returns true or false)
local function is_enemy(turret, target)
    WT.dprint("Entered function is_enemy(" .. WT.print_name(turret) .. ", " ..
            WT.print_name(target) .. ").")

    -- Check arguments
    local args = {}
    local msg = nil

    if not (turret and turret.valid) then args[#args +1] = "Turret" end
    if not (target and target.valid) then args[#args +1] = "Target" end
    for _, arg in pairs(args) do msg = msg .. arg .. " is not valid!\n" end
    if msg then error("Wrong arguments for function is_enemy(turret, target):\n" .. msg) end

    -- Check forces of turret and target
    local f = target.force
    local other = (turret.force ~= f)

    -- Return true if target is an enemy of turret
    local ret = (
                    other and not
                    turret.force.get_friend(f) and not
                    turret.force.get_cease_fire(f)
                ) and true or false
    WT.dprint("End of function is_enemy(" .. WT.print_name(turret) .. ", " ..
            WT.print_name(target) .. "). Return: " .. tostring(ret))
    return ret
end



-- Check whether fire dummy actually marks fires. (Returns table of fires or nil)
local function dummy_marks_fire(dummy)
    WT.dprint("Entered function dummy_marks_fire(" .. WT.print_name_id(dummy) .. ") on tick " .. game.tick ..".")

    -- Check argument
    if not (dummy and dummy.valid) then
      return
        --~ error("Wrong arguments for function dummy_marks_fire(dummy): Dummy is not valid!\n")
    end

    local fires = dummy.surface.find_entities_filtered{
        type = "fire",
        position = dummy.position,
        radius = WT.fire_dummy_radius,
    }
WT.show("radius", WT.fire_dummy_radius)
    WT.show("Fires found around " .. WT.print_name_id(dummy), fires and table_size(fires))
    if table_size(fires) == 0 then
        WT.dprint("No fire around " .. WT.print_name_id(dummy) .. ": removing dummmy!")
        dummy.destroy()
        return nil
    else
        for k, v in pairs(fires) do
            WT.show(tostring(k), v.name)
        end
    end
    WT.dprint("End of function dummy_marks_fire(" .. WT.print_name_id(dummy) .. ") on tick " .. game.tick .. ".")
    return fires
end


-- Search for enemies within the turret's range (returns nil or table of entities).
-- Expects: turret (entity)
local function find_enemies(turret)
    WT.dprint("Entered function find_enemies(" .. WT.print_name_id(turret) .. ") on tick " .. game.tick .. ".")

    -- Check arguments
    local args = {}
    local msg = nil

    if not (turret and turret.valid) then msg = "Turret is not valid!\n" end
    if msg then error("Wrong arguments for function find_enemies(turret, targets):\n" .. msg) end

    if not global.WT_turrets[turret.unit_number] then
        WT.dprint("Turret is not in list!")
        return
    end

    -- Enemies found in the direction the turret is facing
    local enemies_area = nil
    -- Enemies found within max_range around the turret
    local enemies_radius = nil
    -- Temporaty list/return value
    local enemies = nil
    -- Other players and their vehicles are less likely to attack than biters/spitters.
    -- Therefore, we prioritize them (first valid enemy found will be targetted).
    local attack
    -- Only water turrets look for fire dummies…
    if turret.name == WT.water_turret_name then
        attack = { WT.fire_dummy_name, "car", "character", "unit" }
    else
        attack = { "car", "character", "unit" }
    end
    -- Determine search area in the direction the turret is facing
    local area = global.WT_turrets[turret.unit_number].area or WT.get_turret_area(turret)


    -- Look for different enemy types
    for _, targets in pairs(attack) do
        -- Reset search results
        enemies = {}
        enemies_area = {}
        enemies_radius = {}

        -- Get enemies in the direction the turret is facing
        if targets ~= WT.fire_dummy_name then
            enemies = turret.surface.find_entities_filtered{
                type = targets,
                area = area
            }
        -- Special treatment for fire dummies
        elseif turret.type == WT.turret_type and turret.name == WT.water_turret_name then
            enemies = turret.surface.find_entities_filtered{
                type = WT.fire_dummy_type,
                name = targets,
                area = area
            }
        end
        if enemies then
            for _, enemy in pairs(enemies) do
                if is_enemy(turret, enemy) and is_in_range(turret, enemy) then
                    enemies_area[enemy.unit_number] = enemy
                end
            end
        end
        -- Get enemies in the direction the turret is facing
--~ WT.show("targets", targets)
--~ WT.show("targets ~= " .. WT.fire_dummy_name, targets ~= WT.fire_dummy_name)
        if targets ~= WT.fire_dummy_name then
--~ WT.show("Not attacking fire dummy. Target", targets)
            enemies = turret.surface.find_entities_filtered{
                type = targets,
                position = turret.position,
                radius = turret.prototype.turret_range
            }
        -- Special treatment for fire dummies
        --~ elseif turret.type == WT.turret_type and turret.name == WT.water_turret_name then
        else
--~ WT.show("Attacking fire dummy. Target", targets)
            enemies = turret.surface.find_entities_filtered{
                type = WT.fire_dummy_type,
                name = targets,
                position = turret.position,
                radius = turret.prototype.turret_range
            }
        end
--~ WT.show(targets .. " found in radius", enemies)

--~ WT.show("enemies", enemies)
--~ WT.show("enemies and true or false", enemies and true or false)
        if enemies then
            for _, enemy in pairs(enemies) do
                WT.show("_", _)
                WT.show("enemy", enemy)
                -- No need to check is_enemy here: This list is just for quick reference,
                -- every entity in enemies_area has already been checked for is_enemy and
                -- is_in_range
                if is_in_range(turret, enemy) then
                    enemies_radius[enemy.unit_number] = WT.print_name_id(enemy)
                end
            end
        end

        enemies = {}
        WT.show(targets .. " in area", enemies_area)
        WT.show(targets .. " in radius", enemies_radius)

        -- Compile final list: enemies must be in enemies_area and enemies_radius,
        -- and they must belong to an enemy force
        if enemies_area and enemies_radius then
            for index, enemy in pairs(enemies_area) do
                WT.show("index", index)
                WT.show("enemy", enemy)
                --~ if enemies_radius[index] and is_enemy(turret, enemy) then
                --~ if enemies_radius[index] then
                    --~ if enemy.type == WT.fire_dummy_type and enemy.name == WT.fire_dummy_name then
                        --~ if dummy_marks_fire(enemy) then
                            --~ enemies[#enemies + 1] = enemy
                        --~ else
                            --~ enemy.destroy()
                        --~ end
                    --~ else
                        --~ enemies[#enemies + 1] = enemy
                    --~ end
                --~ end
                -- We actually need only one target, so we can quit after the first match!
                if enemies_radius[index] then
                    enemies[#enemies + 1] = enemy
                    if enemy.type == WT.fire_dummy_type and
                       enemy.name == WT.fire_dummy_name and
                       not dummy_marks_fire(enemy) then

                        enemy.destroy()
                    end
                    break
                end
            end
        end
WT.show(targets .. " (final list)", enemies)
WT.show("table_size(" .. targets .. ")", enemies and table_size(enemies))
        -- Return immediately if we've found at least one enemy.
        if table_size(enemies) > 0 then
            WT.dprint("Found enemies -- returning immediately!")
            break
        end
    end

    WT.dprint("Finished search for enemies. Found " .. tostring(enemies and table_size(enemies) or "none") .. ".")
    WT.dprint("End of function find_enemies(" .. WT.print_name_id(turret)  .. ") on tick " .. game.tick .. ".")
    return enemies
end

-- Search for fire (returns table of entities)
local function find_fire(turret)
    WT.dprint("Entered function find_fire(" .. WT.print_name(turret) .. ") on tick " .. game.tick .. ".")

    -- Check argument
    if not (turret and turret.valid) then
        error("Wrong arguments for function find_fire(turret):\nTurret is not valid!\n")
    end

    -- Fires found in the direction the turret is facing
    local fires_area = {}
    -- Fires found within max_range around the turret
    local fires_radius = {}
    -- Fires list/return value
    local fires = nil
    -- Determine search area in the direction the turret is facing
    local area = global.WT_turrets[turret.unit_number].area or WT.get_turret_area(turret)
    -- Fires don't have a unit_number, so we need to define a handle to identify them
    local id = ""

    -- Get fires in the direction the turret is facing
    fires = turret.surface.find_entities_filtered{
        type = "fire",
        area = area
    }
    if fires then
        for _, fire in pairs(fires) do
            if is_in_range(turret, fire) then
                fires_area[#fires_area + 1] = fire
            end
        end
    end
    -- Get all fires around turret position (radius: turret range)
    --~ fires = nil
    fires = turret.surface.find_entities_filtered{
        type = "fire",
        position = turret.position,
        radius = turret.prototype.turret_range
    }
    if fires then
        for _, fire in pairs(fires) do
            if is_in_range(turret, fire) then
                fires_radius[#fires_radius + 1] = fire
            end
        end
    end
    fires = {}
--~ WT.show("fires_area", fires_area)
--~ WT.show("number", table_size(fires_area))
--~ WT.show("fires_radius", fires_radius)
--~ WT.show("number", table_size(fires_radius))

    -- Compile final list: fires must be in fires_area and fires_radius,
    --~ -- and they must belong to an enemy force
    if table_size(fires_area) > 0 and table_size(fires_radius) > 0 then
        for a, a_fire in pairs(fires_area) do
            for r, r_fire in pairs(fires_radius) do
                if a_fire.position.x == r_fire.position.x and
                    a_fire.position.y == r_fire.position.y then
WT.dprint("Found fire in area and radius on position " .. serpent.block(a_fire.position))
                    -- Add fire to list
                    fires[#fires + 1] = a_fire
                    -- Found one fire at this position already, so we can skip this in further tests!
                    fires_radius[r] = nil
                    break
                end
            end
        end
    end

    WT.dprint("End of function find_fire(" .. WT.print_name(turret) .. ") on tick " .. game.tick .. ".")
    return fires
end


-- Target enemies or fire
local function target_enemy_or_fire(turret_id)
    WT.dprint("Entered function target_enemy_or_fire(" ..
                WT.print_name_id(global.WT_turrets[turret_id].entity) .. ") on tick " .. game.tick .. ".")

    -- Check argument
    local msg = "Wrong arguments for function target_enemy_or_fire(turret_id):\n"
    if not (turret_id) then
        error(msg .. "Turret ID " .. tostring(turret_id) .. " is not valid!")
    end

    local turret = global.WT_turrets[turret_id] and global.WT_turrets[turret_id].entity

    ------------------------------------------------------------------------------------
    -- Leave early?
    ------------------------------------------------------------------------------------

    -- Return if turret is not in list (function was called for some other entity for some reason)
    if not turret then
        return
    -- Remove invalid turret from list
    elseif not turret.valid then
        WT.dprint(WT.print_name_id(turret) .. " is not valid!")
        global.WT_turrets[id] = nil
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
    WT.dprint("Checking for enemies or fire around " .. WT.print_name_id(turret).. "." )

    local tu = turret.prototype.attack_parameters
    local range = tu.range
    local min_range = tu.min_range
    local target = turret.shooting_target

WT.show("target", target)
    -- Turret attacks something.
    if target then
        WT.dprint(WT.print_name_id(turret) .. ": shooting at " .. WT.print_name_id(target) .. ".")
        -- Turret attacks worms or spawners -- stop it!
        if target.type == WT.spawner_type or
               target.type == WT.worm_type or
               target.type == WT.artillery_type then

            WT.dprint(WT.print_name_id(turret) .. ": attacks " .. WT.print_name_id(target) .. ".")
            turret.shooting_target = {nil}
            --~ WT.dprint("Reset -- calling target_enemy_or_fire(event) again!")
                -- (Temporarily disabled for 0.18.3)
                --~ target_enemy_or_fire(turret_id)
        -- Fire dummy was attacked
        elseif target.type == WT.fire_dummy_type and target.name == WT.fire_dummy_name then
WT.show("Turret attacks fire (target)", WT.print_name_id(target))
            -- Steam turret attacks fire dummies -- stop it!
            if turret.name == WT.steam_turret_name then
                WT.dprint(WT.print_name_id(turret) .. ": attacks " .. WT.print_name_id(target) .. ".")
                turret.shooting_target = {nil}

                --~ WT.dprint("Found " .. WT.print_name(turret) ..
                      --~ "shooting at fire dummies -- leaving target_enemy_or_fire(" .. tostring(turret_id) ..
                      --~ ") to start over again!")
                -- (Temporarily disabled for 0.18.3)
                --~ target_enemy_or_fire(turret_id)
                --~ return

            -- Water turret attacks fire dummy -- remove dummy if it marks no fire!
            elseif not dummy_marks_fire(target) then
                WT.dprint("No fires around " .. WT.print_name_id(target) ..
                          ". Targetting new fire: " .. WT.print_name_id(enemy) .. ".")
                turret.shooting_target = nil
                target.destroy()
            end
                                -- (Temporarily disabled for 0.18.3)
                                -- --~ target_enemy_or_fire(turret.unit_number)
                --~ -- If enemies are around, stop fighting fire!
                --~ WT.dprint("Fighting fire, looking for enemies …")
                --~ -- Compile list of enemies for turret
                --~ local enemies = find_enemies(turret)
--~ WT.show("enemies", enemies and table_size(enemies))
                --~ if enemies then
                    --~ for _, enemy in pairs(enemies) do
                        --~ -- Set new target to first enemy we can shoot at (unless it's a fire dummy)
                        --~ if enemy.valid then
                            --~ -- Switch target if enemy is not a fire dummy
                            --~ if not (enemy.type == WT.fire_dummy_type or enemy.name == WT.fire_dummy_name) then
                                --~ WT.dprint("Found enemy: " .. WT.print_name_id(enemy) .. ".")
                                --~ turret.shooting_target = enemy
                                --~ return
                            --~ -- Switch target if current target has no fires around it
                            --~ elseif not (target and target.valid and dummy_marks_fire(target)) then
                                --~ WT.dprint("No fires around " .. WT.print_name_id(target) .. ". Targetting new fire: " .. WT.print_name_id(enemy) .. ".")
                                --~ turret.shooting_target = enemy
                                --~ -- (Temporarily disabled for 0.18.3)
                                --~ -- --~ target_enemy_or_fire(turret.unit_number)
                            --~ end
                        --~ end
                    --~ end
                --~ end
            --~ -- Water turret attacks something other than fire
            --~ elseif target.name ~= WT.fire_dummy_name and target.type ~= WT.fire_dummy_type then
--~ WT.show("Water turret attacks enemy (target)", WT.print_name_id(target))
                --~ -- If fires are around, stop fighting enemies!
                --~ WT.dprint("Fighting fire, looking for enemies …")
                --~ -- Compile list of enemies for turret
                --~ local fires = find_fires(turret)
--~ WT.show("enemies", fires and table_size(fires))
                --~ if fires then
                    --~ for _, fire in pairs(fires) do
                        --~ -- Set new target to first fire we can shoot at
                        --~ if fire.valid then
                            --~ -- Switch target if we don't attack a fire dummy
                            --~ if (fire.type == WT.fire_dummy_type or fire.name == WT.fire_dummy_name) then
                                --~ WT.dprint("Found enemy: " .. WT.print_name_id(enemy) .. ".")
                                --~ turret.shooting_target = enemy
                                --~ return
                            --~ -- Switch target if current target has no fires around it
                            --~ elseif not (target and target.valid and dummy_marks_fire(target)) then
                                --~ WT.dprint("No fires around " .. WT.print_name_id(target) .. ". Targetting new fire: " .. WT.print_name_id(enemy) .. ".")
                                --~ turret.shooting_target = enemy
                                --~ -- (Temporarily disabled for 0.18.3)
                                --~ -- --~ target_enemy_or_fire(turret.unit_number)
                            --~ end
                        --~ end
                    --~ end
                --~ end
WT.show(tostring(WT.print_name_id(turret) .. ".shooting_target"), turret.shooting_target)
--~ WT.show("target.name", target and target.name)
--~ WT.show("target.health", target and target.health)
            -- Turret attacks something else. That's probably OK.
        else
            WT.dprint(WT.print_name_id(turret) .. ": attacks " ..
                        WT.print_name_id(target) .. ".")
        end
    end


    -- Return if turret has a target
    if target then
        WT.dprint("Leaving early: " .. turret.name .. " is already shooting at " .. target.name .. "!")
        return
    end

    -- Search for fires to attack if turret is water turret
    if turret.name == WT.water_turret_name then
--~ WT.show("global.WT_turrets", global.WT_turrets)
        local dummy_list = global.WT_turrets[turret.unit_number].fire_dummies or {}
        -- Prune list
        for d, dummy in ipairs(dummy_list) do
            if not dummy_marks_fire(dummy) then
                dummy.destroy()
                global.WT_turrets[turret.unit_number].fire_dummies[d] = nil
                dummy_list[d] = nil
            end
        end

        -- Find fires if list is empty
-- Need to make sure dummy list exists!
        if table_size(dummy_list) == 0 then

            local fires = find_fire(turret)
            if table_size(fires) > 0 then
    WT.show("fires", fires)
                local dummy = {}
                local count = 0
                for _, fire in pairs(fires) do
    WT.show("Fire", fire)
                    -- Create fire dummy
                    if fire.valid then
    WT.show(fire.name .. " (id)", fire.unit_number)
                        dummy = fire.surface.create_entity{
                            name = WT.fire_dummy_name,
                            position = fire.position,
                            force = WT.fire_dummy_force,
                        }
                        WT.show("Created fire dummy", WT.print_name_id(dummy))
                        -- Store dummy
                        count = count + 1
                        global.WT_turrets[turret.unit_number].fire_dummies[count] = dummy
                    end
                end
            end
        end
    end

    WT.dprint(WT.print_name_id(turret) .. " is idle -- looking for enemies …")
    -- Compile list of enemies for turret
    local enemies = find_enemies(turret)
    if enemies then
        for _, enemy in pairs(enemies) do
            -- Attack first enemy we can shoot at
            if enemy.valid then
                turret.shooting_target = enemy
                break
            end
        end

    -- No enemies found!
    else
        WT.dprint(WT.print_name_id(turret) .. " is loaded with " .. tostring(ammo or "nothing"))
    end

    WT.dprint("End of function target_enemy_or_fire(" ..
            WT.print_name_id(global.WT_turrets[turret_id].entity) .. ") on tick " .. game.tick .. ".")
end



















------------------------------------------------------------------------------------
--                                 Event handlers                                 --
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Act on turrets
local function on_tick(event)
WT.show("global.WT_turrets", global.WT_turrets)
    for id, turret in pairs(global.WT_turrets) do
WT.dprint("on_tick: " .. WT.print_name_id(turret.entity))
WT.show("Turret data: ", turret)
WT.show("event tick: ", event.tick)
        -- Remove invalid turrets from list
        if not (turret.entity and turret.entity.valid) then
            global.WT_turrets[id] = nil
            WT.dprint("Removed turret " .. tostring(id) .. " from list because it was not valid.")
        -- Don't act before the tick stored with turret
        elseif turret.tick <= event.tick then
WT.dprint("May act on turret")
            local turret_id = WT.swap_turrets(id)
WT.show("Returned from swap_turrets, got turret_id", turret_id)
            if turret_id and global.WT_turrets[turret_id].entity.valid then
                -- Turret has not been replaced
                if turret_id == id then
                    WT.dprint("Kept " .. WT.print_name_id(turret.entity) .. ".")
                -- New turret!
                else
                    WT.dprint("Replaced turret " .. tostring(id) .. " with " ..
                                WT.print_name_id(global.WT_turrets[turret_id].entity) .. ".")
                    -- Remove old turret from list
                    global.WT_turrets[id] = nil
                end

                -- Set next action tick
                global.WT_turrets[turret_id].tick = event.tick + WT.action_delay
                -- Find a target
                target_enemy_or_fire(turret_id)

            -- This should never be reached!
            else
                error("Something went wrong! Turret with id ".. tostring(turret_id) ..
                      "doesn't exist!\n" .. serpent.block(global.WT_turrets))
            end
        else
WT.dprint("Nothing to do!")
WT.show(global.WT_turrets)
        end
    end
end


------------------------------------------------------------------------------------
-- Turret killed something
local function turret_kill(event)
    WT.dprint("Entered function turret_kill(" .. WT.print_name_id(event.entity) .. ").")

    local turret = event.cause

    WT.show("Killed entity", event.entity.name)
    WT.show("Killer", turret and turret.name)
    WT.show("Damage type", event.damage_type and event.damage_type.name)
    -- Turret should look for a new target immediately if it has killed something
    if turret and turret.valid then
        -- Reset shooting_target! (It's still set to the killed entity, so target_enemy_or_fire
        -- won't do anything if we don't remove it.)
        turret.shooting_target = {nil}
        -- (Temporarily disabled for 0.18.3)
        --~ target_enemy_or_fire(turret.unit_number)
    end

    WT.dprint("End of function turret_kill(" .. WT.print_name_id(event.entity) .. ").")
end


------------------------------------------------------------------------------------
-- Extinguish_fire
local function extinguish_fire(event)
    WT.dprint("Entered function extinguish_fire(" .. WT.print_name_id(event.entity) .. ").")

    local dummy = event.entity
    local fires = dummy.surface.find_entities_filtered{
        type = "fire",
        position = dummy.position,
        radius = WT.fire_dummy_radius,
    }
    --~ WT.show("fires", fires)

    if fires then
        for _, fire in pairs(fires) do
            fire.destroy()
        end
    end
    WT.dprint("Extinguished " .. tostring(table_size(fires)) .. " fires around position " ..
                tostring(dummy.position) .. ".")

    WT.dprint("End of function extinguish_fire(" .. WT.print_name_id(event.entity) .. ").")
end

------------------------------------------------------------------------------------
-- Remove fire dummies without fires around them
local function remove_fire_dummies(event)
    WT.dprint("Entered function remove_fire_dummies(tick " .. tostring(event.tick) .. ").")

    for surface_name, surface in pairs(game.surfaces) do
        WT.dprint("Looking for fire dummies on surface " .. surface_name .. ".")
        -- Get dummies on surface
        local dummies = surface.find_entities_filtered{
            type = WT.fire_dummy_type,
            name = WT.fire_dummy_name,
        }

        -- Check each dummy if there are fires around it
        for _, dummy in pairs(dummies) do
            -- Remove dummy if there is no fire in range
             if not dummy_marks_fire(dummy) then
                dummy.destroy()
                WT.dprint("Removed " .. WT.print_name_id(dummy) ..
                            " from surface " .. surface_name .. ".")
            end
        end
        WT.dprint("Done.")
    end
    WT.dprint("End of function remove_fire_dummies(tick " .. tostring(event.tick) .. ").")
end

------------------------------------------------------------------------------------
-- on_built
local function on_built(event)
    WT.dprint("Entered function on_built(" .. WT.print_name(event.created_entity) .. ").")

    local entity = event.created_entity or event.entity

    -- Filtering events still doesn't work, so this function could also be entered when
    -- something other than our turrets were built. So, just filter once here as well!
    --~ if entity and entity.valid then
    if not (entity.type == WT.turret_type and
            entity.name == WT.steam_turret_name or
            entity.name == WT.water_turret_name)
            then
        WT.dprint("Other entity was created -- nothing to do!")
        return
    end

    if entity and entity.valid then
        global.WT_turrets[entity.unit_number] = {
            ["entity"] = entity,
            ["tick"] = event.tick,
            -- Calculate the rectangular area (2*range x range) in the direction the
            -- turret is facing. It will be intersected with the circular area around
            -- the turret (radius = range) when searching for enemies or fires.
            -- (Recalculate when turret is rotated or moved.)
            ["area"] = WT.get_turret_area(entity),
            --~ -- We store the original position so we can detect if the turret has been
            --~ -- moved (e.g. with the "Picker Dollies" mod), and recalculate the area
            --~ -- it attacks.
            --~ ["original_position"] = entity.position,
        }
    end

    WT.dprint("End of function on_built(" .. WT.print_name(entity) .. ").")
end

------------------------------------------------------------------------------------
-- script_raised_built
-- (Can't use filters for script_raised_X, so we do the filtering here.)
local function script_raised_built(event)
    WT.dprint("Entered function script_raised_built(" .. WT.print_name(event.entity) ..").")

    local entity = event.entity

    if entity and entity.valid and
        (entity.name == WT.steam_turret_name or
         entity.name == WT.water_turret_name) then

        --~ global.WT_turrets[entity.unit_number] = {
            --~ ["entity"] = entity,
            --~ ["tick"] = event.tick
        --~ }
        on_built(event)
    end

    WT.dprint("End of function script_raised_built(" .. WT.print_name(entity) .. ").")
end


------------------------------------------------------------------------------------
-- on_remove
local function on_remove(event)
    WT.dprint("Entered function on_remove(" .. WT.print_name(event.entity) .. ").")

    local entity = event.entity

    -- Filtering events still doesn't work, so this function could also be entered when
    -- something other than our turrets were built. So, just filter once here as well!
    --~ if entity then
    if entity and entity.valid and
        (entity.name == WT.steam_turret_name or
         entity.name == WT.water_turret_name) then

        global.WT_turrets[entity.unit_number] = nil
        WT.dprint("Removed entity " .. entity.name .. " with id " .. entity.unit_number)
    end

    WT.dprint("End of function on_remove(" .. WT.print_name(entity) .. ").")
end


------------------------------------------------------------------------------------
-- script_raised_destroy
-- (Can't use filters for script_raised_X, so we do the filtering here.)
local function script_raised_destroy(event)
    WT.dprint("Entered function script_raised_destroy(" .. WT.print_name(event.entity) .. ").")

    local entity = event.entity

    if entity and
        (entity.name == WT.steam_turret_name or
         entity.name == WT.water_turret_name) then

        global.WT_turrets[entity.unit_number] = nil

    end

    WT.dprint("End of function script_raised_destroy(" .. WT.print_name(entity) .. ").")
end


------------------------------------------------------------------------------------
-- on_player_rotated_entity
local function on_player_rotated_entity(event)
    WT.dprint("Entered function on_player_rotated_entity(" .. WT.print_name_id(event.entity) .. ").")

    local entity = event.entity

    if entity.name == WT.steam_turret_name or entity.name == WT.water_turret_name then
        WT.dprint(entity.name .. " has been moved: recalculating area!")
        global.WT_turrets[entity.unit_number].area = WT.get_turret_area(entity)
    end

    WT.dprint("End of function on_player_rotated_entity(" .. WT.print_name_id(entity) .. ").")
end


------------------------------------------------------------------------------------
-- Picker Dollies: on_moved
local function on_moved(event)
    WT.dprint("Entered function on_moved(" .. WT.print_name_id(event.moved_entity) .. ").")

    local entity = event.moved_entity

    if entity.name == WT.steam_turret_name or entity.name == WT.water_turret_name then
        WT.dprint(entity.name .. " has been moved: recalculating area!")
        global.WT_turrets[entity.unit_number].area = WT.get_turret_area(entity)
    end

    WT.dprint("End of function on_moved(" .. WT.print_name_id(entity) .. ").")
end

------------------------------------------------------------------------------------
-- Init
local function init()
    WT.dprint("Entered function init().")
    log("Entered function init().")

    ------------------------------------------------------------------------------------
    -- Enable debugging if necessary
    WT.debug_in_log = game.active_mods["_debug"] and true or false

    ------------------------------------------------------------------------------------
    -- Initialize global tables
    global = global or {}
    global.WT_turrets = global.WT_turrets or {}
WT.dprint("global.WT_turrets: " .. serpent.block(global.WT_turrets))

    ------------------------------------------------------------------------------------
    -- Make sure our recipe is enabled if it should be
    for f, force in pairs(game.forces) do
        if force.technologies.turrets.researched then
           force.technologies.turrets.researched = false
           force.technologies.turrets.researched = true
           WT.dprint("Reset technology \"turrets\" for force " .. tostring(f))
       end
    end

    ------------------------------------------------------------------------------------
    -- Forces

    -- Create force for fire dummy if it doesn't exist yet.
    if not game.forces[WT.fire_dummy_force] then
        game.create_force(WT.fire_dummy_force)
    end


    -- Check all forces
    for name, force in pairs(game.forces) do
        WT.show(tostring(name), table_size(force.players))
        -- Ignore dummy force
        if force.name ~= WT.fire_dummy_force then
            -- If force has players, make it an enemy of fire dummies
            if table_size(force.players) > 0 then
                force.set_friend(WT.fire_dummy_force, false)
                force.set_cease_fire(WT.fire_dummy_force, false)
            -- Forces without players are neutral to fire dummies
            else
                force.set_friend(WT.fire_dummy_force, false)
                force.set_cease_fire(WT.fire_dummy_force, true)
            end
        end
        WT.show(tostring(name .. " (friend)"), force.get_friend(WT.fire_dummy_force))
        WT.show(tostring(name .. " (cease_fire)"), force.get_cease_fire(WT.fire_dummy_force))
    end

    ------------------------------------------------------------------------------------
    -- Mod compatibility

    -- Compatibility with "Picker Dollies" -- add event handler
    if remote.interfaces["PickerDollies"] and
       remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then

        script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), on_moved)
        WT.dprint("Registered handler for \"dolly_moved_entity_id\" from \"PickerDollies\".")
    end

    WT.dprint("End of function init().")
end

------------------------------------------------------------------------------------
-- on_load
local function on_load()
    log("Entered function on_load().")

    -- Turn debugging on or off
--    script.on_nth_tick(1, function()
--        WT.debug_in_log = (game and game.active_mods["_debug"]) and true or false
--        WT.dprint("Debugging is " .. tostring(WT.debug_in_log and "on" or "off"))

--        script.on_nth_tick(1, nil)
--    end)

    WT.debug_in_log = script.active_mods["_debug"] and true or false

log("Debug in log: " .. tostring(WT.debug_in_log))
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
    WT.dprint("Entered function on_entity_damaged(" .. WT.print_name_id(event.entity) .. ").")
--~ WT.show("event.cause.name", event.cause and event.cause.name)
WT.show("event.entity.name", event.entity and event.entity.name)
WT.show("event.entity.unit_number", event.entity and event.entity.unit_number)
WT.show("event.entity.health", event.entity and event.entity.health)
WT.show("event.entity.prototype.max_health", event.entity and event.entity.prototype.max_health)
WT.show("event.damage_type.name", event.damage_type and event.damage_type.name)
WT.show("event.final_damage_amount", event.final_damage_amount)
WT.show("event.final_health", event.final_health)
WT.show("event.force", event.force)
--~ WT.show("event", event)

WT.show("Correct damage type", (event.damage_type.name == WT.steam_damage_name or event.damage_type.name == WT.water_damage_name))

    ------------------------------------------------------------------------------------
    -- Only act on our turrets' damage
    -- (Needed for Factorio 0.17 only because it doesn't support event filtering by damage_type yet!)
    -- (Better add this for 0.18 as well because event filtering doesn'work reliably yet.)
    if not ((event.damage_type.name == WT.steam_damage_name) or
            (event.damage_type.name == WT.water_damage_name)) then
        WT.dprint("Wrong damage type -- nothing to do!")
        return
    end

    ------------------------------------------------------------------------------------
    -- Fire dummy was attacked -- remove it immediately if there are no fires around it!
    local entity = event.entity
    local turret = event.cause
    if entity and entity.type == WT.fire_dummy_type and entity.name == WT.fire_dummy_name then
WT.show("dummy_marks_fire(" .. WT.print_name_id(entity) .. ")", dummy_marks_fire(entity))
        if not dummy_marks_fire(entity) then
            WT.dprint("Removing " .. WT.print_name_id(entity) .. " because there are no fires near it.")
            entity.destroy()
            WT.dprint("Done.")
            -- Reset target if one of our turrets caused the damage
            if turret and turret.name == WT.water_turret_name then
                turret.shooting_target = {nil}
                -- (Temporarily disabled for 0.18.3)
                --~ target_enemy_or_fire(turret.unit_number)
            end
        end
        return
    end

    ------------------------------------------------------------------------------------
    -- Return if we didn't do the damage
    if not turret or (turret.name ~= WT.steam_turret_name and turret.name ~= WT.water_turret_name) then
        WT.dprint("Leaving function on_entity_damaged(" .. WT.print_name(event.entity) ..
                    ") early -- damage was caused by " .. WT.print_name_id(turret) .. ".")
        return
    end

    ------------------------------------------------------------------------------------
    -- Return if wrong entity was attacked
    if turret and
       -- Water turret damaged something else than fire dummy
       (turret.name == WT.water_turret_name and entity.name ~= WT.fire_dummy_name) or
       -- Steam turret damaged fire dummy
       (turret.name == WT.steam_turret_name and entity.name == WT.fire_dummy_name) then

        turret.shooting_target = {nil}
        return
    end

    local ammo = turret.fluidbox[1]
    local damage = event.final_damage_amount
    local damage_type = event.damage_type

    ------------------------------------------------------------------------------------
    -- Restore health to entity if it belongs to us and has health _property_ (not necessarily health)
    if turret.force == entity.force and entity.health ~= nil then
        entity.health = entity.health + damage
        WT.dprint("Leaving function on_entity_damaged(" .. WT.print_name(event.entity) .. ") early -- restored health.")
        return
    end

    ------------------------------------------------------------------------------------
    -- We damaged a spawner or a worm/turret -- stop it!
    if entity.type == WT.spawner_type or
            entity.type == WT.worm_type or
            entity.type == WT.artillery_type then

        turret.shooting_target = {nil}
        WT.dprint("Leaving function on_entity_damaged(" .. WT.print_name_id(entity) .. ") early -- resetting target for " .. WT.print_name_id(turret) .. ".")
        -- (Temporarily disabled for 0.18.3)
        --~ target_enemy_or_fire(turret.unit_number)
        return
    end

    ------------------------------------------------------------------------------------
    -- We damaged something that doesn't belong to us!
    -- Modify steam damage according to its temperature (base temperature is 165 °C)
    -- Applying increased damage only makes sense if hot steam was used and
    -- if the damaged entity survived
    if  ammo and ammo.name == "steam" and ammo.temperature ~= 165 and entity.health > 0 then
WT.show("ammo.temperature: ", ammo.temperature)
WT.show("ammo.temperature / 165: ", ammo.temperature / 165)
WT.dprint("Adjusting damage and entity health")
        -- Temporarily restore health because base damage has already been applied
        entity.health = entity.health + damage
        -- Calculate increased damage
        damage = damage * ammo.temperature / 165
        -- Subtract increased damage from health
        entity.health = entity.health - damage
    end
WT.show("Entity health: ", entity.health)
    WT.dprint("End of function on_entity_damaged(" .. WT.print_name_id(event.entity) .. ").")
end


------------------------------------------------------------------------------------
--                           Registering event handlers                           --
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Turret was created (for-loop is needed because filters can't be applied to an
-- array of events!)
for _, event in pairs({
                        defines.events.on_built_entity,
                        defines.events.on_robot_built_entity,
                    }) do
    script.on_event(event, on_built, {
            {filter = "type", type = WT.turret_type},
            {filter = "name", name = WT.steam_turret_name, mode = "and"},
            {filter = "name", name = WT.water_turret_name, mode = "or"}
        }
    )
end

------------------------------------------------------------------------------------
-- These events can't be filtered, so the function called includes filtering
script.on_event({
                    defines.events.script_raised_built,
                    defines.events.script_raised_revive
                }, script_raised_built)
script.on_event({defines.events.script_raised_destroy}, script_raised_destroy)

------------------------------------------------------------------------------------
-- Turret was rotated
script.on_event(defines.events.on_player_rotated_entity, on_player_rotated_entity)

------------------------------------------------------------------------------------
-- Turret was removed  (for-loop is needed because filters can't be applied to an
-- array of events!)
for _, event in pairs({
                        defines.events.on_player_mined_entity,
                        defines.events.on_robot_mined_entity,
                    }) do

    script.on_event(event, on_remove,{
            {filter = "type", type = WT.fire_dummy_type},
            {filter = "name", name = WT.steam_turret_name, mode = "and"},
            {filter = "name", name = WT.water_turret_name, mode = "or"}
        })
end
-- This event can't be filtered, so the function called includes filtering
script.on_event({defines.events.script_raised_destroy}, script_raised_destroy)


------------------------------------------------------------------------------------
-- Entity died
script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    local cause = event.cause
    local damage_type = event.damage_type
WT.show("entity.name", entity and entity.name)
WT.show("cause.name", cause and cause.name)
WT.show("damage_type", damage_type and damage_type.name)
    -- Turret died
    if entity.type == WT.turret_type and
        (entity.name == WT.steam_turret_name or entity.name == WT.water_turret_name) then

        WT.dprint("Turret died!")
        on_remove(event)
    -- Fire dummy died
    elseif entity.type == WT.fire_dummy_type and entity.name == WT.fire_dummy_name then
        WT.dprint("Fire dummy died!")
        extinguish_fire(event)
        WT.dprint(tostring(cause.name) .. " extinguished fires. Looking for new target now.")
        -- (Temporarily disabled for 0.18.3)
        --~ if cause and cause.name == WT.water_turret_name then
            --~ target_enemy_or_fire(cause.unit_number)
        --~ end
    -- Turret killed something
    elseif damage_type == WT.steam_damage_name or damage_type == WT.water_damage_name or
            cause and (cause.name == WT.steam_turret_name or cause.name == WT.water_turret_name) then
        WT.dprint("Turret killed something!")
        turret_kill(event)
    -- Nothing to do
    else
        WT.dprint(WT.print_name_id(entity) .. " was killed by " .. WT.print_name_id(cause))
    end
end)

------------------------------------------------------------------------------------
-- Initialize game (Also registers handler for entities moved with "Picker Dollies" if it's active)
script.on_init(init)
script.on_configuration_changed(init)
script.on_event({
                    defines.events.on_player_created,
                    defines.events.on_player_joined_game,
                    defines.events.on_player_changed_force,
                    defines.events.on_player_removed,
                    defines.events.on_force_created,

                    defines.events.on_runtime_mod_setting_changed
                }, init)
script.on_load(on_load)

------------------------------------------------------------------------------------
-- Entity damaged
script.on_event(defines.events.on_entity_damaged, on_entity_damaged, {
        -- Entities were damaged by our turrets
        -- (Heal own entities; increase steam damage for enemy entities; check if fire
        --  dummies have any fire near them)
        {filter = "damage-type", type = WT.steam_damage_name},
        {filter = "damage-type", type = WT.water_damage_name, mode = "or"},
})

------------------------------------------------------------------------------------
-- Check turrets on every tick (will bail out immediately if turret's registered action tick
-- is in the future)
script.on_event(defines.events.on_tick, on_tick)

------------------------------------------------------------------------------------
-- Remove fire dummies with no fires around them every 30 minutes
script.on_nth_tick(30*60*60, remove_fire_dummies)


------------------------------------------------------------------------------------
--                    FIND LOCAL VARIABLES THAT ARE USED GLOBALLY                 --
--                              (Thanks to eradicator!)                           --
------------------------------------------------------------------------------------
setmetatable(_ENV,{
  __newindex = function (self,key,value) --locked_global_write
    error('\n\n[ER Global Lock] Forbidden global *write*:\n'
      .. serpent.line{key = key or '<nil>',value = value or '<nil>'} .. '\n')
    end,
  __index   =function (self,key) --locked_global_read
    error('\n\n[ER Global Lock] Forbidden global *read*:\n'
      .. serpent.line{key = key or '<nil>'} .. '\n')
    end ,
  })
