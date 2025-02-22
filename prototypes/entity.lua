local WT = require('__WaterTurret__/common')("WaterTurret")

local MOD_PIX = WT.mod_root .. "graphics/"
local ICONS = MOD_PIX .. "icons/"
local BASE_PIX = "__base__/graphics/entity/flamethrower-turret/"

--~ local WT.water_turret_tint = { r = 0.25, g = 0.677, b = 0.75, a = 1 }
--~ local WT.extinguisher_turret_tint = { r = 0.981, g = 0.059, b = 0.059, a = 1}
--~ local WT.extinguisher_turret_tint = { r = 0.961, g = 0.181, b = 0.181, a = 1}

-- 1, 1.5, 2, 2.5, 3
local water_pressure_factor = WT.water_turret_pressure > 1 and
                                      (1 + WT.water_turret_pressure / 2) or 1
local extinguisher_pressure_factor = WT.extinguisher_turret_pressure > 1 and
                                      (1 + WT.extinguisher_turret_pressure / 2) or 1

------------------------------------------------------------------------------------
--                             Make new ammo category                             --
------------------------------------------------------------------------------------
data:extend({
  {
    type = "ammo-category",
    name = WT.ammo_category,
    order = "WaterTurret"
  },
})


------------------------------------------------------------------------------------
--                              Make new damage types                             --
------------------------------------------------------------------------------------
data:extend({
  {
    type = "damage-type",
    name = WT.water_damage_name,
    order = "WaterTurret-a"
  },
  {
    type = "damage-type",
    name = WT.steam_damage_name,
    order = "WaterTurret-b"
  },
  {
    type = "damage-type",
    name = WT.fire_ex_damage_name,
    order = "WaterTurret-c"
  },
})


------------------------------------------------------------------------------------
--                          Make new trigger target types                         --
------------------------------------------------------------------------------------
data:extend({
  -- For water and steam turrets
  {
    type = "trigger-target-type",
    name = WT.trigger_target_mobile
  },
  -- For all turrets, if "Clean acid" setting is on
  {
    type = "trigger-target-type",
    name = WT.trigger_target_acid_dummy
  },
  -- For water and fire extinguisher turrets
  {
    type = "trigger-target-type",
    name = WT.trigger_target_fire_dummy
  },
  -- For targets we don't want to attack ("Will-o'-the-wisps" units for now)
  {
    type = "trigger-target-type",
    name = WT.trigger_target_ignore
  },
})


------------------------------------------------------------------------------------
--                              Make new sticker type                             --
------------------------------------------------------------------------------------
local sticker = table.deepcopy(data.raw.sticker["slowdown-sticker"])
sticker.name = WT.slowdown_sticker_name
sticker.target_movement_modifier = WT.slowdown_factor
sticker.vehicle_speed_modifier = WT.slowdown_factor

data:extend({sticker})


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                     Entities                                   --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                                      Fire                                      --
-- Create a fire that's created whenever a fire is spawned. It will burn for its  --
-- complete TTL and not have the burned-patch phase, so that turrets won't seem   --
-- to attack empty spots on the ground. We used a fire animation placed on top of --
-- the dummy before, but this was only fake, without doing fire damage.           --
------------------------------------------------------------------------------------
local WT_fire = table.deepcopy(data.raw.fire["fire-flame"])
WT.show("WT_fire.maximum_lifetime", WT_fire.maximum_lifetime)
WT.show("WT_fire.burnt_patch_lifetime", WT_fire.burnt_patch_lifetime)
WT_fire.name = WT.fake_fire_name
--~ WT_fire.initial_lifetime = WT_fire.maximum_lifetime + WT_fire.burnt_patch_lifetime
WT_fire.initial_lifetime = WT_fire.maximum_lifetime
--~ WT_fire.maximum_lifetime = WT_fire.maximum_lifetime + WT_fire.burnt_patch_lifetime
WT_fire.burnt_patch_lifetime = 0
WT_fire.on_fuel_added_action = nil

data:extend({WT_fire})

WT.show("WT_fire.burnt_patch_pictures", WT_fire.burnt_patch_pictures)
------------------------------------------------------------------------------------
--                                     Dummies                                    --
------------------------------------------------------------------------------------


-- Corpse mimics the burnt patch of the fire
local burnt_patch = {
  type = "corpse",
  name = WT.burnt_patch,
  icon = "__base__/graphics/icons/small-scorchmark.png",
  --~ icon_size = 32,
  icon_size = 64,
  flags = {"placeable-neutral", "not-on-map", "placeable-off-grid"},
  collision_box = {{-1.5, -1.5}, {1.5, 1.5}},

  collision_mask = {layers = {doodad = true}, "not-colliding-with-itself"},

  selection_box = {{-1, -1}, {1, 1}},
  selectable_in_game = false,
  time_before_removed = 60 * 60 * 3, -- 3 minutes
  final_render_layer = "ground-patch-higher2",
  subgroup = "remnants",
  order="d[remnants]-b[scorchmark]-a[small]",
      --blend_mode="additive-soft",
  animation = {
    width = 115,
    height = 56,
    frame_count = 1,
    direction_count = 1,
    filename = MOD_PIX .. "new_burnt_patch.png",
    variation_count = 9
  },
  ground_patch = {
    sheet = {
      width = 115,
      height = 56,
      frame_count = 1,
      direction_count = 1,
      filename = MOD_PIX .. "new_burnt_patch.png",
      variation_count = 9,
    }
  },
  ground_patch_higher = {
    sheet = {
      width = 115,
      height = 56,
      frame_count = 1,
      direction_count = 1,
      filename = MOD_PIX .. "new_burnt_patch.png",
      variation_count = 9,
      blend_mode = "normal"
    }
  }
}
data:extend({ burnt_patch })


------------------------------------------------------------------------------------
-- Fire dummy
--~ local fire_dummy = {
  --~ type = WT.dummy_type,
  --~ name = WT.fire_dummy_name,
  --~ picture = {
    --~ -- filename = mods["_debug"] and MOD_PIX .. "red_dot.png" or MOD_PIX .. "blank.png",
    --~ filename = (WT.debug_in_log or WT.debug_in_game) and
                --~ MOD_PIX .. "red_dot.png" or MOD_PIX .. "blank.png",
    --~ size = 64
  --~ },
  --~ healing_per_tick = 0,
  --~ max_health = 2,
  --~ -- Resistances will be added later in data-updates.lua, when we know about all
  --~ -- defined damage-types!
  --resistances = r,
  --~ allow_copy_paste = false,
  --~ collision_box = {{0, 0}, {0, 0}},
  --~ flags = {
    --~ "placeable-off-grid",
    --~ "not-repairable",
    --~ "not-on-map",
    --~ "not-blueprintable",
    --~ "not-deconstructable",
    --~ "hidden",
    --~ "not-flammable",
    --~ "no-copy-paste",
    --~ "not-selectable-in-game"
  --~ },
  --~ trigger_target_mask = { WT.trigger_target_fire_dummy }
--~ }
local fire_dummy = util.table.deepcopy(data.raw[WT.dummy_type]["defender"])

fire_dummy.name = WT.fire_dummy_name

fire_dummy.attack_parameters.ammo_type.action.action_delivery = nil
fire_dummy.attack_parameters.range = 0
fire_dummy.damaged_trigger_effect = {
    damage_type_filters = {WT.water_damage_name, WT.fire_ex_damage_name},
    type = "create-trivial-smoke",
    smoke_name = "soft-fire-smoke",
    color = {r = 0.75, g = 0.75, b = 0.75, a = 0.75}
}
fire_dummy.destroy_action = nil
fire_dummy.dying_explosion = nil
fire_dummy.dying_trigger_effect = nil
fire_dummy.flags = {
    "placeable-off-grid",
    "not-repairable",
    "not-on-map",
    "not-blueprintable",
    "not-deconstructable",
    "not-flammable",
    "no-copy-paste",
    "not-selectable-in-game"
}

fire_dummy.hidden = true
fire_dummy.follows_player = false
fire_dummy.icon = WT.debug_in_log and MOD_PIX .. "/red_dot.png" or MOD_PIX .. "/blank.png"
fire_dummy.icon_mipmaps = 1
fire_dummy.icon_size = 64
fire_dummy.max_health = 2
fire_dummy.max_speed = 0
fire_dummy.max_to_charge = 0
fire_dummy.speed = 0
fire_dummy.speed_multiplier_when_out_of_energy = 1
fire_dummy.water_reflection = nil
fire_dummy.working_sound = nil
fire_dummy.trigger_target_mask = { WT.trigger_target_fire_dummy }

fire_dummy.selectable_in_game = WT.debug_in_log
fire_dummy.allow_copy_paste = false
fire_dummy.create_ghost_on_death = false
fire_dummy.alert_when_damaged = false
-- Health bar will be invisible if selection_box is {{0,0},{0,0}}!
fire_dummy.selection_box = {{0,0},{0,0}}

--~ WT.show("fire pictures", data.raw["fire"]["fire-flame"].pictures)
for _, picture in ipairs({"idle", "shadow_idle", "in_motion", "shadow_in_motion"}) do
    fire_dummy[picture] = {
        frame_count = 1,
        direction_count = 1,
        filename = WT.debug_in_log  and MOD_PIX .. "/red_dot.png" or MOD_PIX .. "/blank.png",
        size = 64,
        mipmap_count = 1,
    }
--~ -- WT.show(picture, fire_dummy[picture])
end

-- Create fake fire when dummy is placed
fire_dummy.created_effect = {
  type = "direct",
  action_delivery = {
    type = "instant",
    target_effects = {
      type = "create-entity",
      entity_name = WT.fake_fire_name,
      --~ -- ignore_collision_condition = true,
      trigger_created_entity = false,
      offset_deviation = { {0, 0}, {0, 0} },
      offsets ={ {0, 0} }
    }
  }
}
data:extend({ fire_dummy })


------------------------------------------------------------------------------------
-- Acid dummy
if WT.clean_acid_splashes then
  local acid_dummy = table.deepcopy(data.raw[WT.dummy_type][WT.fire_dummy_name])
  acid_dummy.name = WT.acid_dummy_name
  --~ table.insert(acid_dummy.trigger_target_mask, WT.trigger_target_mobile)
  acid_dummy.trigger_target_mask = { WT.trigger_target_acid_dummy }
  acid_dummy.damaged_trigger_effect.damage_type_filters = {WT.water_damage_name, WT.fire_ex_damage_name, WT.steam_damage_name}
  acid_dummy.icon = WT.debug_in_log and MOD_PIX .. "/green_dot.png" or MOD_PIX .. "/blank.png"
  for _, picture in ipairs({"idle", "shadow_idle", "in_motion", "shadow_in_motion"}) do
      acid_dummy[picture] = {
          frame_count = 1,
          direction_count = 1,
          filename = WT.debug_in_log and MOD_PIX .. "/green_dot.png" or MOD_PIX .. "/blank.png",
          size = 64,
          mipmap_count = 1,
      }

  --~ WT.show(picture, fire_dummy[picture])
  end
  acid_dummy.created_effect = nil

  data:extend({ acid_dummy })
WT.dprint("acid-dummy: %s", { data.raw[WT.dummy_type][WT.acid_dummy_name] })
end


------------------------------------------------------------------------------------
--                                  Water turret                                  --
--                   Images are changed at the end of the file!                   --
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Remnants
local waterentity_remnants = util.table.deepcopy(data.raw.corpse["flamethrower-turret-remnants"])

waterentity_remnants.name = WT.water_turret_name .. "-remnants"
--~ waterentity_remnants.icon = MOD_PIX .. "water-turret-icon.png"
waterentity_remnants.icons = {
  {icon = ICONS .."turret-icon.png"},
  {icon = ICONS .. "turret-icon-raw.png", tint = WT.water_turret_tint}
}
waterentity_remnants.icon_size = 64


------------------------------------------------------------------------------------
-- Entity
local waterentity = util.table.deepcopy(data.raw[WT.turret_type]["flamethrower-turret"])

waterentity.name = WT.water_turret_name
--~ waterentity.icon = MOD_PIX .. "water-turret-icon.png"
waterentity.icons = {
  {icon = ICONS .."turret-icon.png"},
  {icon = ICONS .. "turret-icon-raw.png", tint = WT.water_turret_tint}
}
waterentity.icon_size = 64
waterentity.icon_mipmaps = 0
waterentity.corpse = waterentity_remnants.name
waterentity.minable = {mining_time = 0.5, result = WT.water_turret_name}
waterentity.max_health = 900
--~ waterentity.fluid_buffer_size = 200
waterentity.fluid_buffer_size = 200 * water_pressure_factor
waterentity.fluid_buffer_input_flow = waterentity.fluid_buffer_size / 60 / 5 -- 5s to fill the buffer
waterentity.activation_buffer_ratio = 0.25
waterentity.muzzle_animation = {
  filename = BASE_PIX .. "flamethrower-turret-muzzle-fire.png",
  line_length = 8,
  width = 1, -- 17
  height = 1, -- 41
  frame_count = 32,
  axially_symmetrical = false,
  direction_count = 1,
  blend_mode = "additive",
  scale = 0.5,
  shift = {0.015625 * 0.5, -0.546875 * 0.5 + 0.05}
}
waterentity.muzzle_light = {intensity = 0.7, size = 3}
waterentity.prepare_range = 60
waterentity.shoot_in_prepare_state = false

waterentity.attack_parameters = {
  type = "stream",
  cooldown = 10,
  --range = 50, --30
  range = WT.water_turret_range, --30
  min_range = 6,

  turn_range = 1.0 / 3.0,
  fire_penalty = 15,
  health_penalty = WT.health_factor,
  lead_target_for_projectile_speed = 0.2* 0.75 * 1.5, -- this is same as particle horizontal speed of flamethrower fire stream

  fluids = {
    {type = "water"},
    -- Moved over to new entity "steam-turret"
    --~ {type = "steam", damage_modifier = 5}
  },
  fluid_consumption = WT.water_turret_pressure,
  gun_center_shift = {
    north = {0,-1.7},
    east = {0.4,-1},
    south = {0,-1},
    west = {-0.4,-1.2}
  },
  gun_barrel_length = 0.4,

  ammo_category = WT.ammo_category,
  ammo_type = {
    action = {
      type = "direct",
      action_delivery = {
        type = "stream",
        stream = "water-stream",
        source_offset = {0.15, -0.5}
      }
    }
  },
  cyclic_sound = {
    begin_sound = {
      {
        filename = "__base__/sound/fight/flamethrower-start.ogg",
        volume = 0 -- 0.7
      }
    },
    middle_sound = {
      {
        filename = "__base__/sound/fight/flamethrower-mid.ogg",
        volume = 0 -- 0.7
      }
    },
    end_sound = {
      {
        filename = "__base__/sound/fight/flamethrower-end.ogg",
        volume = 0 -- 0.7
      }
    }
  }
}
data:extend({waterentity, waterentity_remnants})


------------------------------------------------------------------------------------
-- Stream

--~ local water_color ={r = 0.000, g = 0.286, b = 0.949, a = .5}
--~ local steam_color ={r = 0.714, g = 0.769, b = 0.800, a = .5}
--~ local fire_ex_color ={r = 0.774, g = 0.777, b = 0.313, a = .5}
local f = data.raw.fluid
local water_color = f["water"] and  f["water"].base_color
local steam_color = f["steam"] and f["steam"].base_color
local fire_ex_color = WT.fire_ex_fluid_tint


WT.show("steam color", steam_color)
local waterstream = util.table.deepcopy(data.raw["stream"]["flamethrower-fire-stream"])
waterstream.name = "water-stream"
waterstream.stream_light = {intensity = 0, size = 0}
waterstream.ground_light = {intensity = 0, size = 0}
waterstream.smoke_sources = {
  {
    name = "soft-fire-smoke",
    frequency = 0, --0.25,
    position = {0.0, 0}, -- -0.8},
    starting_frame_deviation = 0
  }
}


waterstream.action = {
  {
    type = "area",
    radius = 2.5,
    -- Next line is needed so that fire dummies can actually be attacked!
    ignore_collision_condition = true,
    action_delivery = {
      type = "instant",
      target_effects = {
        {
          type = "create-sticker",
          sticker = WT.slowdown_sticker_name,
          trigger_created_entity = true,
          show_in_tooltip = true
        },
        {
          type = "damage",
          damage = {
            amount = WT.water_base_damage_amount * water_pressure_factor,
            type = WT.water_damage_name
          },
          apply_damage_to_trees = false
        }
      }
    }
  },
}

waterstream.spine_animation = {
  --~ filename = MOD_PIX .. "water-turret-stream-spine-water.png",
  filename = MOD_PIX .. "water-turret-stream-spine-raw.png",
  blend_mode = "additive",
  --tint = {r = 1, g = 1, b = 1, a = 0.5},
  tint = water_color,
  line_length = 4,
  width = 32,
  height = 18,
  frame_count = 32,
  axially_symmetrical = false,
  direction_count = 1,
  --~ animation_speed = 2,
  animation_speed = WT.water_turret_pressure,
  shift = {0, 0}
}
waterstream.shadow = {
  filename = BASE_PIX .. "../acid-projectile/projectile-shadow.png",
  line_length = 5,
  width = 28,
  height = 16,
  frame_count = 33,
  priority = "high",
  shift = {-0.09, 0.395}
}
waterstream.particle = {
  --~ filename = MOD_PIX .. "water-turret-explosion-water.png",
  filename = MOD_PIX .. "water-turret-explosion-raw.png",
  tint = water_color,
  priority = "extra-high",
  width = 64,
  height = 64,
  frame_count = 32,
  line_length = 8
}
data:extend({waterstream})


------------------------------------------------------------------------------------
--                                  Steam turret                                  --
--                   Images are changed at the end of the file!                   --
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
-- Entity
local steamentity = table.deepcopy(data.raw[WT.turret_type][WT.water_turret_name])
local steamstream = table.deepcopy(data.raw["stream"]["water-stream"])

steamentity.name = WT.steam_turret_name
--~ steamentity.localised_name = {"entity-name." .. WT.water_turret_name}
--~ steamentity.localised_description = {"entity-description." .. WT.water_turret_name}
steamentity.placeable_by = {item = WT.water_turret_name, count = 1}
steamentity.attack_parameters.fluids = {
    {type = "steam", damage_modifier = WT.steam_damage_modifier}
}

steamentity.attack_parameters.ammo_type = {
  category = "flamethrower",
  action = {
    type = "direct",
    action_delivery = {
      type = "stream",
      stream = "steam-stream",
      source_offset = {0.15, -0.5}
    }
  }
}


------------------------------------------------------------------------------------
-- Stream
steamstream.name = "steam-stream"
--~ steamstream.spine_animation.filename = MOD_PIX .. "water-turret-stream-spine-steam.png"
--~ steamstream.particle.filename = MOD_PIX .. "water-turret-explosion-steam.png"
steamstream.spine_animation.tint = steam_color
steamstream.particle.tint = steam_color
steamstream.action[1].action_delivery.target_effects[2] = {
  type = "damage",
  damage = {
    amount = WT.water_base_damage_amount * water_pressure_factor,
    type = WT.steam_damage_name
  },
  apply_damage_to_trees = false
}
data:extend({steamentity, steamstream})


------------------------------------------------------------------------------------
--         Fire extinguisher turret using special Fire extinguisher fluid         --
--                   Images are changed at the end of the file!                   --
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
-- Remnants
local extinguisherentity_remnants = table.deepcopy(data.raw.corpse["flamethrower-turret-remnants"])
extinguisherentity_remnants.name = WT.extinguisher_turret_name .. "-remnants"
--~ extinguisherentity_remnants.icon = MOD_PIX .. "extinguisher-turret-icon.png"
extinguisherentity_remnants.icons = {
  {icon = ICONS .. "turret-icon.png", tint = WT.extinguisher_turret_tint}
  }


------------------------------------------------------------------------------------
-- Entity
local extinguisherentity = table.deepcopy(data.raw[WT.turret_type][WT.water_turret_name])
extinguisherentity.name = WT.extinguisher_turret_name
extinguisherentity.localised_name = WT.hardened_pipes and
  {"entity-name." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-name." .. WT.extinguisher_turret_name}
extinguisherentity.localised_description = WT.hardened_pipes and
  {"entity-description." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-description." .. WT.extinguisher_turret_name}
--~ extinguisherentity.icon = MOD_PIX .. "extinguisher-turret-icon.png"
WT.dprint("Hardened pipes: %s\tlocalised name: %s", {WT.hardened_pipes, extinguisherentity.localised_name})

extinguisherentity.icons = {
  {icon = ICONS .. "turret-icon.png", tint = WT.extinguisher_turret_tint}
}
extinguisherentity.fluid_buffer_size = 200 * extinguisher_pressure_factor
extinguisherentity.fluid_buffer_input_flow = extinguisherentity.fluid_buffer_size / 60 / 5 -- 5s to fill the buffer


extinguisherentity.corpse = extinguisherentity_remnants.name
extinguisherentity.placeable_by = {item = WT.extinguisher_turret_name, count = 1}
extinguisherentity.minable.result = WT.extinguisher_turret_name
extinguisherentity.attack_parameters.fluids = {
  {
    type = WT.fire_ex_fluid,
    damage_modifier = WT.extinguisher_fluid_damage_modifier * WT.extinguisher_turret_damage_modifier
  },
  {
    type = "water",
    damage_modifier = WT.extinguisher_turret_damage_modifier,
  }
}
extinguisherentity.attack_parameters.range = WT.extinguisher_turret_range
extinguisherentity.attack_parameters.rotate_penalty = 1

extinguisherentity.attack_parameters.ammo_type = {
  category = "flamethrower",
  action = {
    type = "direct",
    action_delivery = {
      type = "stream",
      stream = "extinguisher-stream",
      source_offset = {0.15, -0.5}
    },
  },
  target_type = "entity"
}


------------------------------------------------------------------------------------
-- Bonuses

-- 360° rotation
extinguisherentity.attack_parameters.turn_range = 1
-- Shoot twice per tick
extinguisherentity.attack_parameters.cooldown = 0.5
-- Higher rotation speed
extinguisherentity.rotation_speed = extinguisherentity.rotation_speed * 1.5


------------------------------------------------------------------------------------
-- Stream
local extinguisherstream = table.deepcopy(data.raw["stream"]["water-stream"])
extinguisherstream.name = "extinguisher-stream"
--~ extinguisherstream.spine_animation.filename = MOD_PIX .. "water-turret-stream-spine-steam.png"
extinguisherstream.spine_animation.tint = fire_ex_color
extinguisherstream.spine_animation.animation_speed = extinguisher_pressure_factor
--~ extinguisherstream.particle.filename = MOD_PIX .. "water-turret-explosion-steam.png"
extinguisherstream.particle.tint = fire_ex_color
extinguisherstream.action[1].action_delivery.target_effects[2] = {
  type = "damage",
  damage = {
    amount = WT.water_base_damage_amount * extinguisher_pressure_factor,
    type = WT.fire_ex_damage_name
  },
  apply_damage_to_trees = false
}
data:extend({extinguisherentity, extinguisherentity_remnants, extinguisherstream})


------------------------------------------------------------------------------------
--                      Fire extinguisher turret using water                      --
--  This is a duplicate entity -- only the name will and the stream will change!  --
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
-- Entity
local extinguisherwaterentity = table.deepcopy(data.raw[WT.turret_type][WT.extinguisher_turret_name])
extinguisherwaterentity.name = WT.extinguisher_turret_water_name
extinguisherwaterentity.attack_parameters.ammo_type.action.action_delivery.stream = "extinguisherwater-stream"


------------------------------------------------------------------------------------
-- Stream
local extinguisherwaterstream = table.deepcopy(data.raw["stream"]["extinguisher-stream"])
extinguisherwaterstream.name = "extinguisherwater-stream"
extinguisherwaterstream.spine_animation.tint = water_color
extinguisherwaterstream.particle.tint = water_color
data:extend({extinguisherwaterentity, extinguisherwaterstream})


------------------------------------------------------------------------------------
--                                Coloring turrets                                --
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
-- Color remnants

--[[local function color_remnants(entity, tint)

  local layer = table.deepcopy(data.raw.corpse["flamethrower-turret-remnants"].animation.layers[1])

  layer.filename = MOD_PIX .. "turret-gun-remnants-raw.png"
  layer.tint = tint



  table.insert(entity.animation.layers, 2, layer)--]]--[[
end
--~ log("WT.water_turret_tint: " .. serpent.block(WT.water_turret_tint))
color_remnants(data.raw.corpse[WT.water_turret_name .. "-remnants"], WT.water_turret_tint)
color_remnants(data.raw.corpse[WT.extinguisher_turret_name .. "-remnants"], WT.extinguisher_turret_tint)


local function color_layer(layers, image, tint)
  local new_layer = table.deepcopy(layers[1])
  new_layer.filename = MOD_PIX .. image
  new_layer.tint = tint
  new_layer.apply_runtime_tint = false
  if new_layer.hr_version then
    new_layer.hr_version.filename = MOD_PIX .. "hr-" .. image
    new_layer.hr_version.tint = tint
    new_layer.hr_version.apply_runtime_tint = false
  end
  table.insert(layers, 2, new_layer)
end


--]]
------------------------------------------------------------------------------------
--Color turret base
--[[

local function color_base(turret, tint)

  for d, direction in ipairs({"north", "east", "south", "west"}) do
    color_layer(turret.base_picture[direction].layers,
                  "turret-base-" .. direction .. "-raw.png", tint)
  end
end

--color_base(data.raw[WT.turret_type][WT.water_turret_name], WT.water_turret_tint)
--color_base(data.raw[WT.turret_type][WT.steam_turret_name], WT.water_turret_tint)
--color_base(data.raw[WT.turret_type][WT.extinguisher_turret_name], WT.extinguisher_turret_tint)
---color_base(data.raw[WT.turret_type][WT.extinguisher_turret_water_name], WT.extinguisher_turret_tint)

--~ WT.exchange_images({ "north", "east", "south", "west" },
                    --~ "extinguisher-turret-base-%NAME%.png",
                    --~ data.raw[WT.turret_type][WT.extinguisher_turret_name].base_picture)


------------------------------------------------------------------------------------
-- Color rotatable gun 
--[[

local function color_gun(turret, tint)
  local function color(layer, image, tint)
    layer.filename = MOD_PIX .. image
    layer.tint = tint
    layer.apply_runtime_tint = false
    if layer.hr_version then
      layer.hr_version.filename = MOD_PIX .. "hr-" .. image
      layer.hr_version.tint = tint
      layer.hr_version.apply_runtime_tint = false
    end
  end

  for d, direction in ipairs({"north", "east", "south", "west"}) do
    for a, animation in ipairs({
      "folded_animation", "preparing_animation", "folding_animation",
    }) do
      color(turret[animation][direction].layers[1], "turret-gun-extension-raw.png", tint)
    end

    for a, animation in ipairs({
      "prepared_animation", "attacking_animation", "ending_attack_animation"
    }) do
      color(turret[animation][direction].layers[1], "turret-gun-raw.png", tint)
    end
  end
end

color_gun(data.raw[WT.turret_type][WT.water_turret_name], WT.water_turret_tint)
color_gun(data.raw[WT.turret_type][WT.steam_turret_name], WT.water_turret_tint)
color_gun(data.raw[WT.turret_type][WT.extinguisher_turret_name], WT.extinguisher_turret_tint)
color_gun(data.raw[WT.turret_type][WT.extinguisher_turret_water_name], WT.extinguisher_turret_tint)

--]]

