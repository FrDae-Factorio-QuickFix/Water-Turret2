# What does this mod do?
This mod provides water turrets that can be loaded either with water or with steam. These early turrets are cheap to make and available as soon as turrets have been researched. They are not meant to be used offensively, but are very useful for defense because they can slow down enemy hordes, so your other turrets have more time to kill enemies.

Water turrets that are loaded with water cause only very little damage -- but they can also extinguish fire. On the other hand, water turrets loaded with steam won't care about fire, but they deal more damage because steam is hot. Actually, the damage caused by steam will increase with steam temperature, so hook up your turrets to some really hot steam if you want to give visitors a steamy welcome!

There are also fire-extinguisher turrets that will require more advanced technology. These turrets won't attack enemies at all, but they are much better at fighting fire than the normal turrets. Unlike water turrets, they will rotate in a full circle (360°), so you won't have to build as many turrets to cover all directions.

All turrets may also clean up the puddles of acid spitters and worms have left on the ground. This has to be enabled in the settings.

---

# Start-up settings

## Interval to check turrets
Smaller values will give the mod more control about what the turrets attack. You may increase this value if you have trouble with low UPS. However, turrets will only check for new fires and acid splashes in this interval, so if this value is too big, turrets may seem to ignore these targets even though they are right in front of them.

## Turrets clean up acid splashes
If enabled, all turrets will look for puddles of acid on the ground within their range -- no matter what fluid they are loaded with. However, when cleaning up acid the same modifiers as for default targets will be applied, so water turrets loaded with hot steam or fire extinguisher turrets will finish the job faster than water turrets that shoot just water.

## Water turret range / Fire extinguisher turret range
Increasing the range of turrets will also increase the area that needs to be scanned for fires and acid splashes. The default range of 50 tiles should give sufficiently good results, but if you'd really want to push the limit, you can do so on your own risk!

## Choose next target based on enemy health
You can choose to prefer the target with the lowest or with the highest amount of remaining health points. The default is to ignore the health.

## Water turret color / Fire extinguisher turret color
If you don't like the default colors of the turrets, you can assign them another color here. You may use RGB codes, either in HTML notation (e.g. `#40adbf` -- the leading `#` is optional) or as a comma-separated list of decimal numbers in the range 0...255 (e.g. `63.8, 172.7, 191.2` for the same color).

## Water turret pressure modifier / Fire extinguisher turret pressure modifier
Increasing the pressure will make the turrets shoot faster and increase the amount of damage to enemies, fire, and acid splashes. However, it will also drive up the turrets' fluid consumption!

## Fire extinguisher turret damage modifier
Fire extinguisher turrets are more expensive than normal water turrets, so they should be better at putting out fire and cleaning up acid splashes as well. Use this to choose how much better than water turrets they will be!

## Modifier for steam damage
Use this to change the base value of the damage done by water turrets shooting steam. The actual steam damage is calculated by this formula:
```plaintext
final_damage = water_damage * steam_damage_modifier * (steam_temperature/165)
```
In case you wonder about the 165: That's the temperature of steam coming out of a vanilla boiler. So, if you use steam with a lower temperature, it will do less damage.

## Slow-down factor
Mobile targets hit by water or steam will be slowed down to this value (in percent).

## Don't hurt worms / Don't hurt spawners
By default, spawners and worms won't be attacked by water turrets and get full immunity against damage from water or steam.

## Use Hardened pipes
This setting is only available if [Hardened pipes](https://mods.factorio.com/mod/hardened_pipes) is active. When it's enabled, you'll need to research hardened pipes to unlock the technology for fire extinguisher turrets because they will be needed in the recipe.

## Add support for GVV
This setting is only available if [Lua API global Variable Viewer (gvv)](https://mods.factorio.com/mod/gvv) is active. When it's enabled, you can inspect the global table of "Water Turrets". You'll probably only ever need this if you want to help debug this mod.

---

# Compatibility with other mods
This mod should work with other mods introducing new enemies, like [Armoured Biters](https://mods.factorio.com/mod/ArmouredBiters), [Explosive Biters](https://mods.factorio.com/mod/Explosive_biters), [Natural Evolution Enemies](https://mods.factorio.com/mod/Natural_Evolution_Enemies), or [Rampant](https://mods.factorio.com/mod/Rampant). It should also work with mods like [Wildfire](https://mods.factorio.com/mod/Wildfire) that will ignite fires randomly in the world.

If the [Lua API global Variable Viewer (gvv)](https://mods.factorio.com/mod/gvv) is active, you can use it to inspect the global table of this mod.

## [Hardened pipes](https://mods.factorio.com/mod/hardened_pipes)
If compatibility with Hardened pipes is enabled, making fire extinguisher turrets will become much harder as well: You'll need more research to unlock the recipe, the recipe will become more expensive, and setting up production of the turrets will get far more complicated. So why on Nauvis should you use that mod?

For one thing, you may like the challenge that producing the turrets with hardened pipes will become. If that's not enough to convince you, you may appreciate that using hardened pipes in the recipe will make the turrets more resistant or even immune against several damage types. :-)

---

# Credits
- Credits go to [DellAquila](https://mods.factorio.com/user/DellAquila), who made the original version of this mod. (He transferred ownership to me recently.)
- I'm very grateful to [eradicator](https://mods.factorio.com/user/eradicator), who helped me out with great ideas and explanations while I was working on this mod.
- I'm indebted to [Honktown](https://mods.factorio.com/user/Honktown) for explaining why fires behave the way they do.
- Thanks a lot to [darkfrei](https://mods.factorio.com/user/darkfrei) for helping me finally understand how to make graphics!
- Thanks a lot to [Fr_Dae](https://mods.factorio.com/user/Fr_Dae) for providing the French translation, testing before new releases, and some valuable advice for improvements.
- Thanks a lot to [Lily](https://mods.factorio.com/user/IonShield) for make revive this mods.
- Credits go to [PI-c](https://mods.factorio.com/mod/WaterTurret) for the original mods
