
# GPT 5.2 Notes Regarding Worlds Project

## Geography Notes — Landmass Sunlight (Simple / Authoring-First)

Goal: an **achievable** first sunlight model that creates day/night dynamics for the Energy gene without requiring procedural terrain/noise, and that remains a stable seam for future gradients/seasonality.

### Core idea
- A **landmass** defines a daylight window: `sunrise`, `sunset`.
- Sunlight is modeled as a **time-varying energy influx field** (flux), initially uniform across the landmass.
- Agents can “charge” during the day by capturing local flux; at night flux goes to ~0 and they burn stored energy.

### Invariants / coupling constraints
- Geography provides **fields** (e.g., `SunlightFlux`) and does **not** own agents.
- Agents store location; Population owns “agents-in-cell” indexing.
- The sunlight system is a contributor to an energy field; future energy sources are additional contributors.

### Landmass parameters (minimal set)
- `SunriseTime`: time-of-day when flux begins (>0).
- `SunsetTime`: time-of-day when flux ends (>Sunrise in the simplest case).
- `PeakSunFlux`: maximum midday flux scale for this landmass.
- Optional bias knobs (simple, authorable):
	- `DayLengthFactor` (0..1): compresses/extends day length without changing the curve shape.
	- `SeasonStrength` (0..1): scales flux up/down (winter/summer) without changing sunrise/sunset semantics.
	- `SunCurveShape` (enum/float): selects/controls the daylight curve (defaults to smooth half-sine).

### Daylight curve (smooth, cheap)

Definitions:
- Let `t` be the current time-of-day.
- Let `D = SunsetTime - SunriseTime` (daylight duration).
- If `t` is outside the daylight window => flux = 0.

Within daylight, normalize to phase $p \in [0,1]$:
$$
p = \frac{t - sunrise}{D}
$$

Default intensity curve (half-sine):
$$
I(p) = \sin(\pi p)
$$

Then landmass-level sunlight flux is:
$$
SunFlux(t) = PeakSunFlux \cdot I(p)
$$

Notes:
- Starts/ends at 0 with smooth slope; peaks at midday.
- Gives “charge in day / deplete at night” dynamics immediately.

### Optional curve shaping (still simple)
If needed, bias sunrise/midday/sunset profile without new systems:
- Exponent shaping (keeps endpoints at 0):
	$$I'(p) = (\sin(\pi p))^\gamma$$
	- $\gamma > 1$ makes a sharper midday peak; $\gamma < 1$ makes a flatter day.

### Wrap-around handling (future-proof)
If later you allow `SunsetTime` to be “after midnight” (i.e., `sunrise > sunset`), treat daylight as spanning midnight:
- Daylight if `t >= sunrise` OR `t <= sunset`.
- Use wrapped duration $D = (T - sunrise) + sunset$ where $T$ is the day period (e.g., 24h).
- Compute wrapped elapsed similarly before normalizing to $p$.

### Extension points that don’t break the contract
Keep the core contract “time -> landmass flux scalar” stable; add complexity as multipliers:
- Per-cell modifiers: `Shade`, `Slope`, `Cloud`, `Opacity`.
- Gradients: a simple multiplier based on `(x,y)` (e.g., latitude band) without changing the day curve.
- Multiple sources: `SunFlux + GeothermalFlux + ...`.

### Design intent
- Start with uniform sunlight per landmass (fast to implement + render).
- Let Energy gene be the primary consumer of `SunFlux`, and let Perception sample the flux field to create local strategy differences.
- Add “food pools” later as additional resource channels; keep energy conversion in genes, not in geography.

## 2025-12-22

## Geography Notes — Minimal V1 `TCell` Contents (Visualizer + Energy/Perception)

Design target: a `256 x 256` grid that you can render immediately (color-mapping a few floats), while supporting the first two “layer” genes (Energy + Perception) without committing to heavier chemistry.

### Principle: cell = environment state, not occupancy
- Many agents can share a cell; the cell does **not** store agents.
- Population/agent storage maintains indexing “agents in cell” if/when needed.

### Minimal cell fields (high leverage)
Keep V1 brutally small; every additional number costs iteration speed.

Required for day/night + energy harvesting:
- `SolarFlux`: float; written by geography each tick (0 at night).

Required to make movement/perception non-trivial without terrain generation:
- `TraversalCost`: float; movement energy cost multiplier (water is “high cost”, not “blocked”).
- `Opacity`: float; reduces effective perception (cover/density/fog). Optional but very useful for visuals.

Optional but very nice for immediate “interesting” dynamics:
- `Habitable`: float (0..1); used as a mask/weight for regen rules and a convenient basis for “continent-ness”.

### Suggested V1 rendering strategy
- Render `SolarFlux` as brightness (grayscale) to verify day/night timing.
- Render `TraversalCost` or `Habitable` as color tint (land/water separation without booleans).
- Render `Opacity` as darkening/alpha effect.

### Food later (but keep the slot in mind)
When you introduce food/chemistry, avoid inventing a second mechanism. Extend the same “field sampling” model:
- Add `ResourcePools[0..K-1]` (K small, e.g., 2–8) as floats.
- Agents convert pools to usable energy via DNA parameters (efficiency, toxicity, max intake).
- “You ate it, did nothing” becomes a natural outcome when local pool mix doesn’t match metabolism.

### Performance note (habitable list)
An explicit “habitable cell list” is an **index**, not a requirement.
- Start with full-grid loops (simple, correct, easy).
- Add a list/index only when you have a demonstrated hotspot (e.g., diffusion/regeneration over mostly-dead space).

### Contract boundary
For V1, keep the geography API surface basically:
- “Update fields for the tick”
- “Sample cell fields at (x,y) and in a small neighborhood”

Everything else (interpretation, strategy, conversion to behavior) lives in genes.

## Geography Notes — Water Level + Elevation (V1-Friendly)

Motivation: avoid “either/or land vs water” and instead model the planet as continuous terrain with a region waterline. This enables shorelines, shallows, mud, swamps, deep sea, and later tides/flooding without adding systems up-front.

### V1 primitives
- Region: `WaterLevel` (float).
- Cell: `Elevation` (float).

### Derived environment channels (compute, don’t store at first)
- `WaterDepth = max(0, WaterLevel - Elevation)`
	- `0` = dry (at/above waterline)
	- small positive = shallows / shoreline band
	- large = deep water

Then define other channels as smooth functions of `WaterDepth` (and later slope):
- `TraversalCost`: increases with depth; optionally has a “mud bump” around shallow water.
- `Opacity`: can increase with depth (murk) or around shoreline (vegetation), depending on the feel you want.
- Optional “shoreline affinity” channel: peaks near `WaterDepth ≈ 0` for beach/swamp niches.

### Habitability: optional as an explicit channel
It’s valid to have **no** explicit `Habitable` channel if “can you live here?” emerges from pressures:
- If agents can only extract energy/food from certain sources at certain depths, then “habitat” is an outcome, not a label.

If you keep a `Habitable`-like channel at all, treat it as a *generic weighting/mask* for geography’s own regen rules, not as a rule that forbids organisms.

## Energy Notes — Absorption as the Natural “Compatibility” Mechanism

Design intent: instead of hardcoding “fish get nothing from sunlight”, make energy types exist in the environment and make agents differ by **absorption/efficiency** (floats).

### Environment side
- Geography emits energy *by type* (conceptually):
	- e.g., `SolarFlux` (day/night)
	- later: `ThermalFlux`, `ChemicalFlux`, `Detritus`, etc.

### Agent side
- Agent DNA provides an absorption/efficiency vector per energy type:
	- “how well can I convert this environmental channel into stored energy?”
	- values are continuous, so “mostly useless” and “slightly useful” exist naturally.

### Perception + mistakes
Depth-limited perception is a great source of failure modes:
- Perception gene can sample `WaterDepth` (or derived cues) with limited range/precision.
- Agents can mis-estimate depth and pay a big traversal/energy penalty (“oops, deep water”).

### Memory hook (optional, but coherent)
If/when you add memory, the simplest useful memory is empirical:
- “Expected energy delta / traversal cost for a move in this direction / toward this cue”
- This stays local and pressure-driven (no global truth), and fits the current/delta state model.




## Environmental Channels — Current Names (Concise)

Cell-level stored channels (V1):
- `SolarFlux`: time-varying incoming energy per tick at this cell (day/night driver).
- `Elevation`: terrain height; combined with region `WaterLevel` to derive depth/shoreline dynamics.
- `TraversalCost`: movement cost multiplier/penalty implied by local conditions (e.g., deep water expensive, shoreline “mud bump” optional).
- `Opacity`: visibility attenuation / cover / murk; used by Perception sampling and also easy to visualize.

Region-level stored channel (V1):
- `WaterLevel`: region “sea level” reference used to compute water depth from cell elevation.

Derived channels (compute on demand; don’t store at first):
- `WaterDepth`: `max(0, WaterLevel - Elevation)`; 0 = dry, >0 = underwater (shoreline = near 0).


