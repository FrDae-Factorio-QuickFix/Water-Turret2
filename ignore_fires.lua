--------------------------------------------------------------------------------------
-- Turns out the acid splashes left on the ground by worms and spitters are         --
-- actually fires!                                                                  --
--------------------------------------------------------------------------------------
--~ log("Entered file 'ignore_fires'")
local fire_functions = {}


-- Define patterns for names of acid splashes. This list will be used to populate the
-- actual ignore/acid lists (based on the setting)
local patterns = {
  -- Vanilla
  "^acid%-splash%-.+$",
  -- Rampant
  "^.+acid%-fire%-rampant$"
}


local function make_list(patterns)
  local list = {}

  local fires
  -- Control stage
  if game then
    fires = {}
    for name, surface in pairs(game.surfaces) do
      local f = surface.find_entities_filtered{type = "fire"}
      for _, fire in ipairs(f) do
        table.insert(fires, fire.prototype)
      end
    end
    --fires = game.get_filtered_entity_prototypes({
    --  { filter = "type", type = "fire" }
    --}) or {}
  -- Data stage
  elseif mods then
    fires = data.raw.fire
  end

  for fire, _ in pairs(fires) do
--~ log("fire: " .. tostring(fire) .. "\t_: " .. tostring(_))

    for p, pattern in pairs(patterns) do
      if string.match(fire, pattern) then
--~ log("Match found: " .. fire)
        list[fire] = true
        break
      end
    end
  end
--~ log("List: " .. serpent.block(list))
  return list
end


fire_functions.get_ignorelist = function()
  return settings.startup["WT-turrets_clean_acid"].value and {} or make_list(patterns)
end

fire_functions.get_acid = function()
  return settings.startup["WT-turrets_clean_acid"].value and make_list(patterns) or {}
end


return fire_functions
