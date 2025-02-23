local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")

------------------------------------------------------------------------------------
-- Register all existing water turrets

WT.dprint("Entered migration script \"0.18.02.lua\"")

WT.show("storage.WT_turrets", storage.WT_turrets)
if not storage.WT_turrets or table_size(storage.WT_turrets) == 0 then

  ------------------------------------------------------------------------------------
  --                              Register all turrets                              --
  ------------------------------------------------------------------------------------
  storage = storage or {}
  storage.WT_turrets = storage.WT_turrets or {}

  local turrets = {}
  local tick = game.tick

  for name, surface in pairs(game.surfaces) do
    -- Find all entities on surface
    for _, ent in ipairs({WT.steam_turret_name, WT.water_turret_name}) do
      WT.dprint("Searching for %s on surface %s.", { ent, name })

      turrets = surface.find_entities_filtered{
        type = WT.turret_type,
        name = ent
      }
----~ WT.show("Found turrets", turrets)

      -- Register turrets
      for t, turret in pairs(turrets) do
        storage.WT_turrets[turret.unit_number] = {
          -- Store the entity.
          ["entity"] = turret,
          -- Calculate the rectangular area (2*range x range) in the direction the
          -- turret is facing. It will be intersected with the circular area around
          -- the turret (radius = range) when searching for enemies or fires.
          -- (Recalculate when turret is rotated or moved.)
          ["area"] = WT.get_turret_area(turret),
          -- We act a random number of ticks from now. The factor 36000 is used
          -- to spread initialization of turrets that existed before version
          -- 0.18.2 of this mod over a period of 10 minutes.
          ["tick"] = tick + math.floor(math.random() * 36000),
        }

        WT.dprint("%s: Registered %s.", { t, WT.print_name_id(turret) })
      end
      WT.dprint("Done. (%s)", { ent })
    end
  end
WT.show("storage", storage)
end

-- Check that turrets can use the fluid they're hooked up to, exchange them otherwise.
for id, turret in pairs(storage.WT_turrets) do
  local new_id = WT.swap_turrets(id)

  if new_id and storage.WT_turrets[new_id].entity.valid then
    if new_id == id then
      WT.dprint("Kept %s.", { WT.print_name_id(turret.entity) })
    else
      WT.dprint("Replaced turret %s with %s.", {
                id, WT.print_name_id(storage.WT_turrets[new_id].entity)
      })

      -- Remove old turret from list
      storage.WT_turrets[id] = nil
    end
  end
end

WT.dprint("Swapped turrets. Checking ticks!")
for id, turret in pairs(storage.WT_turrets) do
  if turret.entity and turret.entity.valid then
    WT.dprint("ID %s: %s acting on tick %g", { id, WT.print_name(turret.entity), turret.tick })
  else
    WT.dprint("ID %s: Turret doesn't exist!", { id })
  end
end

-- Create force for fire dummy
if not game.forces[WT.dummy_force] then
  game.create_force(WT.dummy_force)
end

WT.dprint("End of migration script \"0.18.02.lua\"")
