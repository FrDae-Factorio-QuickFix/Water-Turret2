local WT = require('__WaterTurret-revived__/common')("WaterTurret-revived")

local MOD_PIX = WT.mod_root .. "graphics/icons/"

------------------------------------------------------------------------------------
--                                      Item                                      --
------------------------------------------------------------------------------------
local wateritem = util.table.deepcopy(data.raw["item"]["flamethrower-turret"])
wateritem.name = WT.water_turret_name
wateritem.localised_name = {"entity-name.WT-water-turret"}
wateritem.localised_description = {"entity-description.WT-water-turret"}

wateritem.place_result = WT.water_turret_name
--~ wateritem.icon = MOD_PIX .. "water-turret-icon.png"
wateritem.icons = {
  {icon = MOD_PIX .."turret-icon.png", icon_size = 64},
  { icon = MOD_PIX .. "turret-icon-raw.png", tint = WT.water_turret_tint, icon_size = 64 }
}


local extinguisheritem = util.table.deepcopy(data.raw["item"]["flamethrower-turret"])
extinguisheritem.name = WT.extinguisher_turret_name
extinguisheritem.localised_name = WT.hardened_pipes and
  {"entity-name." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-name." .. WT.extinguisher_turret_name}
extinguisheritem.localised_description = WT.hardened_pipes and
  {"entity-description." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-description." .. WT.extinguisher_turret_name}

WT.dprint("Hardened pipes: %s\tlocalised name: %s", {WT.hardened_pipes, extinguisheritem.localised_name})

extinguisheritem.place_result = WT.extinguisher_turret_name
--~ extinguisheritem.icon = MOD_PIX .. "extinguisher-turret-icon.png"
extinguisheritem.icons = {
  { icon = "__base__/graphics/icons/flamethrower-turret.png", icon_size = 64 },
  {icon = MOD_PIX .. "turret-icon-raw.png", tint = WT.extinguisher_turret_tint, icon_size = 64}
}


---@diagnostic disable-next-line: assign-type-mismatch
data:extend({ wateritem, extinguisheritem })


------------------------------------------------------------------------------------
--                                      Fluid                                     --
------------------------------------------------------------------------------------
local extinguisherfluid = {
  type = "fluid",
  name = WT.fire_ex_fluid,
  -- icon_size must be defined inside the icons or the icons generated for barrelling
  -- recipes won't be shown correctly!
  icons = {
    --[[{
      icon = MOD_PIX .. "fluid/fire-ex-fluid-icon-turret-bg.png",
      icon_size = 128,
      scale = 0.25
    },
    {
      icon = MOD_PIX .. "fluid/fire-ex-fluid-icon-turret.png",
      icon_size = 128,
      tint = WT.extinguisher_turret_tint,
      scale = 0.25
    },--]]
    {
      icon = MOD_PIX .. "fluid/fire-ex-fluid-icon-fluid-bg.png",
      icon_size = 128,
      scale = 0.25
      --~ tint = WT.fire_ex_fluid_tint,
    },
    {
      icon = MOD_PIX .. "fluid/fire-ex-fluid-icon-fluid.png",
      icon_size = 128,
      scale = 0.25,
      tint = WT.fire_ex_fluid_tint,
    },
  },
  --~ icon_size = 128,
  default_temperature = 25,
  max_temperature = 100,

  heat_capacity = "1kJ",

  subgroup = "fluid",
  -- Need to detach base_color from WT.fire_ex_fluid_tint, if it's just a reference,
  -- the icon will get transparency as well!
  base_color = table.deepcopy(WT.fire_ex_fluid_tint),
  -- flow_color must be different from base_color. We'll calculate it later!
  --~ flow_color = WT.fire_ex_fluid_tint,
  flow_color = {},
  pressure_to_speed_ratio = 0.4,
  flow_to_energy_ratio = 0.59,
  --~ order = "a[fluid]-b[biomass]"
}

-- Make sure there's enough difference between base_color and flow_color that the
-- flow can be seen!
local difference = 0.1
local alpha_factor
local x
for color, value in pairs(extinguisherfluid.base_color) do
WT.dprint("%s: %s", {color, value})
  alpha_factor = (color == "a" or color == 4) and 3 or 1

  x = value * (1 + difference * alpha_factor)
  if x > 1 then
    x = value * (1 - difference * alpha_factor)
  end

WT.dprint("%s: %s\tnew value: %s", {color, value, x})
  extinguisherfluid.flow_color[color] = x
end
WT.show("flow_color", extinguisherfluid.flow_color)


  --~ extinguisherfluid.flow_color.a = 0.5
data:extend({ extinguisherfluid })
