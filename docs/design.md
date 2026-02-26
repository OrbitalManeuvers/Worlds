
# Worlds Design Ideas


## Authoring/Simulating

The authoring process involves designing both resources and geography, in a very approachable, simplified way.

When an authored world is loaded into the simulator, it uses the low resolution "friendly" design spec to populate the simulator data using scaling, randomization, smoothing, etc - into structures with enough resolution to (hopefully) provide interesting results.

Scaling is 8x, so authored regions are 32x32, simulated regions are 256x256.

Authoring with low-resolution relative values allows the simulator freedom during the upscaling to introduce variation, biome smoothing, etc.


## Authoring: Ratings
A core concept of authoring is assigned relative values to various items, such as the growth rate of something, or 


`Rating = (Worst, Horrible, Bad, Normal, Good, Great, Best)`
Low resolution "slider" value to set up basic relative values below. Authoring is done at this low resolution level (the geography, too) and then scaled up for runtime. This approach makes authoring quick and easy, and allows for tuning and variation in the runtime sim.


- Rating
- Proteins
- Consumables
- Resources
- Biomes
- Regions
- Worlds


## Runtime

