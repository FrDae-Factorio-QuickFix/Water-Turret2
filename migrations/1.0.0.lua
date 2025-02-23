log("Entered migration script \"1.0.0.lua\"")

local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")

--~ log("storage table before migration" .. serpent.block(storage))

-- Initialize storage tables
storage = storage or {}
storage.fires = storage.fires or {}
storage.fire_dummies = storage.fire_dummies or {}
storage.WT_turrets = storage.WT_turrets or {}
local dummies

--~ WT.show("game.surfaces", game.surfaces)

-- Remove all fire dummies
for s, surface in pairs(game.surfaces) do

  dummies = surface.find_entities_filtered({
    name = WT.fire_dummy_name,
    type = WT.dummy_type
  })

  WT.dprint("Found %g dummies on surface %s", { table_size(dummies), s })

  for d, dummy in pairs(dummies) do
    dummy.destroy()
  end
end

-- Fix turrets
WT.show("Number of turrets", table_size(storage.WT_turrets))
for t, turret in pairs(storage.WT_turrets) do
  -- Remove invalid turrets
  if not turret.entity and turret.entity.valid then
    storage.WT_turrets[t] = nil
  else

    -- Add an id to the data for easier debugging
    storage.WT_turrets[t].id = t

    -- Add range/min_range
    storage.WT_turrets[t].min_range = turret.entity.prototype.attack_parameters.min_range
    storage.WT_turrets[t].range = turret.entity.prototype.turret_range
    WT.dprint("Added min_range and range to data of %s.", { WT.print_name_id(turret.entity) })

    -- Fix format of bounding boxes of area
    storage.WT_turrets[t].area = WT.get_turret_area(turret.entity)
    WT.dprint("Added area to data of %s", { WT.print_name_id(turret.entity) })

      -- Write data of dummies and fires to turret and storage lists
    if turret.entity.name ~= WT.steam_turret_name then
      storage.WT_turrets[t].fire_dummies = {}
      storage.WT_turrets[t].fires = {}

      --~ WT.find_fire(turret.entity)

    -- Remove entity.fires and entity.fire_dummies from steam turrets
    else
      storage.WT_turrets[t].fire_dummies = nil
      storage.WT_turrets[t].fires = nil
    end

    -- Remove unused value original_position from all turrets
    storage.WT_turrets[t].original_position = nil

  end

end
--~ WT.show("storage table after migration", storage)
--~ WT.show("Number of turrets", table_size(storage.WT_turrets))

WT.dprint("End of migration script \"1.0.0.lua\".")
