local wateritem = util.table.deepcopy(data.raw["item"]["flamethrower-turret"])
wateritem.name = "water-turret"
wateritem.place_result = "water-turret"
wateritem.icon = "__WaterTurret__/graphics/flamethrower-turret.png"
wateritem.icon_size = 32
wateritem.icon_mipmaps = 1
data:extend({wateritem})

local waterrecipe = util.table.deepcopy(data.raw["recipe"]["flamethrower-turret"])
waterrecipe.name = "water-turret"
waterrecipe.enabled = true
waterrecipe.ingredients =
    {
      {"iron-plate", 30},
      {"iron-gear-wheel", 15},
      {"pipe", 10},
      {"offshore-pump", 1}
    }
waterrecipe.result = "water-turret"
data:extend({waterrecipe})

local waterentity = util.table.deepcopy(data.raw["fluid-turret"]["flamethrower-turret"])
waterentity.name = "water-turret"
waterentity.icon = "__WaterTurret__/graphics/flamethrower-turret.png"
waterentity.icon_size = 32
waterentity.icon_mipmaps = 1
waterentity.minable = {mining_time = 0.5, result = "water-turret"}
waterentity.max_health = 900
waterentity.fluid_buffer_size = 200
waterentity.fluid_buffer_input_flow = 250 / 60 / 5 -- 5s to fill the buffer
waterentity.activation_buffer_ratio = 0.25
waterentity.muzzle_animation =
    {
      filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-muzzle-fire.png",
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
waterentity.base_picture =
    {
      north =
      {
        layers =
        {
          -- diffuse
          {
            filename = "__WaterTurret__/graphics/flamethrower-turret-base-north.png",
            line_length = 1,
            width = 80,
            height = 96,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(-2, 14),
            hr_version =
            {
              filename = "__WaterTurret__/graphics/hr-flamethrower-turret-base-north.png",
              line_length = 1,
              width = 158,
              height = 196,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(-1, 13),
              scale = 0.5
            }
          },
          -- mask
          {
            filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-base-north-mask.png",
            flags = { "mask" },
            line_length = 1,
            width = 36,
            height = 38,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(0, 32),
            apply_runtime_tint = true,
            hr_version =
            {
              filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-base-north-mask.png",
              flags = { "mask" },
              line_length = 1,
              width = 74,
              height = 70,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(-1, 33),
              apply_runtime_tint = true,
              scale = 0.5
            }
          },
          -- shadow
          {
            filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-base-north-shadow.png",
            draw_as_shadow = true,
            line_length = 1,
            width = 70,
            height = 78,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(2, 14),
            hr_version =
            {
              filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-base-north-shadow.png",
              draw_as_shadow = true,
              line_length = 1,
              width = 134,
              height = 152,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(3, 15),
              scale = 0.5
            }
          }
        }
      },
      east =
      {
        layers =
        {
          -- diffuse
          {
            filename = "__WaterTurret__/graphics/flamethrower-turret-base-east.png",
            line_length = 1,
            width = 106,
            height = 72,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(-6, 2),
            hr_version =
            {
              filename = "__WaterTurret__/graphics/hr-flamethrower-turret-base-east.png",
              line_length = 1,
              width = 216,
              height = 146,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(-6, 3),
              scale = 0.5
            }
          },
          -- mask
          {
            filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-base-east-mask.png",
            flags = { "mask" },
            apply_runtime_tint = true,
            line_length = 1,
            width = 32,
            height = 42,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(-32, 0),
            hr_version =
            {
              filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-base-east-mask.png",
              flags = { "mask" },
              apply_runtime_tint = true,
              line_length = 1,
              width = 66,
              height = 82,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(-33, 1),
              scale = 0.5
            }
          },
          -- shadow
          {
            filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-base-east-shadow.png",
            draw_as_shadow = true,
            line_length = 1,
            width = 72,
            height = 46,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(14, 8),
            hr_version =
            {
              filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-base-east-shadow.png",
              draw_as_shadow = true,
              line_length = 1,
              width = 144,
              height = 86,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(14, 9),
              scale = 0.5
            }
          }
        }
      },
      south =
      {
        layers =
        {
          -- diffuse
          {
            filename = "__WaterTurret__/graphics/flamethrower-turret-base-south.png",
            line_length = 1,
            width = 64,
            height = 84,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(0, -8),
            hr_version =
            {
              filename = "__WaterTurret__/graphics/hr-flamethrower-turret-base-south.png",
              line_length = 1,
              width = 128,
              height = 166,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(0, -8),
              scale = 0.5
            }
          },
          -- mask
          {
            filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-base-south-mask.png",
            flags = { "mask" },
            apply_runtime_tint = true,
            line_length = 1,
            width = 36,
            height = 38,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(0, -32),
            hr_version =
            {
              filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-base-south-mask.png",
              flags = { "mask" },
              apply_runtime_tint = true,
              line_length = 1,
              width = 72,
              height = 72,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(0, -31),
              scale = 0.5
            }
          },
          -- shadow
          {
            filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-base-south-shadow.png",
            draw_as_shadow = true,
            line_length = 1,
            width = 70,
            height = 52,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(2, 8),
            hr_version =
            {
              filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-base-south-shadow.png",
              draw_as_shadow = true,
              line_length = 1,
              width = 134,
              height = 98,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(3, 9),
              scale = 0.5
            }
          }
        }

      },
      west =
      {
        layers =
        {
          -- diffuse
          {
            filename = "__WaterTurret__/graphics/flamethrower-turret-base-west.png",
            line_length = 1,
            width = 100,
            height = 74,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(8, -2),
            hr_version =
            {
              filename = "__WaterTurret__/graphics/hr-flamethrower-turret-base-west.png",
              line_length = 1,
              width = 208,
              height = 144,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(7, -1),
              scale = 0.5
            }
          },
          -- mask
          {
            filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-base-west-mask.png",
            flags = { "mask" },
            apply_runtime_tint = true,
            line_length = 1,
            width = 32,
            height = 40,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(32, -2),
            hr_version =
            {
              filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-base-west-mask.png",
              flags = { "mask" },
              apply_runtime_tint = true,
              line_length = 1,
              width = 64,
              height = 74,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(32, -1),
              scale = 0.5
            }
          },
          -- shadow
          {
            filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-base-west-shadow.png",
            draw_as_shadow = true,
            line_length = 1,
            width = 104,
            height = 44,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(14, 4),
            hr_version =
            {
              filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-base-west-shadow.png",
              draw_as_shadow = true,
              line_length = 1,
              width = 206,
              height = 88,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(15, 4),
              scale = 0.5
            }
          }
        }
      }
    }
waterentity.attack_parameters =
    {
      type = "stream",
      cooldown = 10,
      range = 50, --30
      min_range = 6,

      turn_range = 1.0 / 3.0,
      fire_penalty = 15,

      -- lead_target_for_projectile_speed = 0.2* 0.75 * 1.5, -- this is same as particle horizontal speed of flamethrower fire stream

      fluids =
      {
        {type = "water"},
        --~ {type = "steam", damage_modifier = 5}
        {type = "steam", damage_modifier = 20}
      },
      fluid_consumption = 1,

      gun_center_shift =
      {
         north = {0,-1.7},
         east = {0.4,-1},
         south = {0,-1},
         west = {-0.4,-1.2}
      },
      gun_barrel_length = 0.4,

      ammo_type =
      {
        category = "flamethrower",
        action =
        {
          type = "direct",
          action_delivery =
          {
            type = "stream",
            stream = "water-stream",
            source_offset = {0.15, -0.5}
          }
        }
      },

      cyclic_sound =
      {
        begin_sound =
        {
          {
            filename = "__base__/sound/fight/flamethrower-start.ogg",
            volume = 0 -- 0.7
          }
        },
        middle_sound =
        {
          {
            filename = "__base__/sound/fight/flamethrower-mid.ogg",
            volume = 0 -- 0.7
          }
        },
        end_sound =
        {
          {
            filename = "__base__/sound/fight/flamethrower-end.ogg",
            volume = 0 -- 0.7
          }
        }
      }
    }
data:extend({waterentity})

local waterstream = util.table.deepcopy(data.raw["stream"]["flamethrower-fire-stream"])
waterstream.name = "water-stream"
waterstream.stream_light = {intensity = 0, size = 0}
waterstream.ground_light = {intensity = 0, size = 0}
waterstream.smoke_sources =
    {
      {
        name = "soft-fire-smoke",
        frequency = 0, --0.25,
        position = {0.0, 0}, -- -0.8},
        starting_frame_deviation = 0
      }
    }
waterstream.action =
    {
      {
        type = "area",
        radius = 2.5,
        action_delivery =
        {
          type = "instant",
          target_effects =
          {
            {
              type = "create-sticker",
              --~ sticker = "stun-sticker"
              sticker = "slowdown-sticker"
            },
            {
              type = "damage",
              damage = { amount = 0.005, type = "physical" },
              apply_damage_to_trees = false
            }
          }
        }
      },
    }
waterstream.spine_animation =
    {
      filename = "__WaterTurret__/graphics/flamethrower-fire-stream-spine.png",
      blend_mode = "additive",
      --tint = {r=1, g=1, b=1, a=0.5},
      line_length = 4,
      width = 32,
      height = 18,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      animation_speed = 2,
      shift = {0, 0}
    }
waterstream.shadow =
    {
      filename = "__base__/graphics/entity/acid-projectile/projectile-shadow.png",
      line_length = 5,
      width = 28,
      height = 16,
      frame_count = 33,
      priority = "high",
      shift = {-0.09, 0.395}
    }
waterstream.particle =
    {
      filename = "__WaterTurret__/graphics/flamethrower-explosion.png",
      priority = "extra-high",
      width = 64,
      height = 64,
      frame_count = 32,
      line_length = 8
    }
data:extend({waterstream})
