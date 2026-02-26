
## 2025-12-22 Copilot GPT-5.2 Chat about Learning

My response to "first agent decisions I want"
- sim subtracts metabolic cost from agent reserve
- agent processing starts with Energy gene. First generation can basically only do `availableEnergy = (reserve - metabolicCost)` and provide that value for subsequent genes. 
- next comes Perception. Lots of intentions here, but first will be energy detection. I haven't thought much about this, but let's assume that early on I will have a channel for a generic `food` that's compatible with everyone, and it's in/on the ground, and it requires a tiny range of water depth - i.e. "land with ground water" or some such, and so it won't be everywhere, but the first Perception gene should be able to map out food levels in all directions, so 8 readings of food levels. (might be a crappy gene model, so let's say close approximations of food levels)
- Next pertinent one to this will be `Motion` and this will generate a direction delta to objects detected by `Perception` so that later genes get the 'how' if they land on deciding motion towards a target is a good idea
- Last there `Cognition` which is going to weigh the perceived targets, evaluate energy reserves, eventually it'll get info from `Perception` about detected agent DNA + velocity vector + range, which lets food take a back seat to survival. But for now, I'm planning for the above types of things to be available, and the `Cognition` gene will put together a final state delta to return back to the sim ("I thought about it, and here's what I'd like to do.") and the sim will update the agent's permanent state if possible/as possible/idk. 


------- end ------------

## Memory + Learning (V1 shape that matches Energy/Perception/Motion/Cognition)

### Plain-English framing
In this sim design, “memory” is just **stored expectations** about what tends to happen when the agent does something in a situation.

“Learning” is the rule that updates those expectations after the agent experiences the result.

So yes: your intuition is right — the agent acts, it gets an outcome, and the difference between **what it expected** and **what actually happened** is the “lesson”.

### What to predict first (keep it achievable)
For your pipeline, the cleanest first prediction target is:
- **Expected net energy change** from a move.

Because almost everything you care about (food, bad terrain, water mistakes) collapses into net energy:
- reward-ish: eating/absorbing energy
- penalty-ish: traversal cost, metabolic cost, drowning penalties, etc.

### Minimal memory state (per-agent)
Given Perception provides 8 directional readings and Motion produces a direction delta, the simplest useful memory is an “8-way expectation table”:
- `ExpectedDeltaE[dir]` for 8 directions (N, NE, E, …)

Interpretation:
- “When I choose direction `dir` under conditions like this, what net energy delta do I typically get?”

You can start even simpler:
- one table per agent, not conditioned on context at all.

That already creates individuality: two agents in the same world can drift into different habits because they experienced different outcomes.

### The learning update (prediction error)
After a step:
- Observe actual net energy outcome: `actualDeltaE`
- Compare to expectation: `expected = ExpectedDeltaE[chosenDir]`
- Error: `error = actualDeltaE - expected`
- Update: `ExpectedDeltaE[chosenDir] += learningRate * error`

That’s it. No heavy ML required.

### How this plugs into your genes
One coherent placement (conceptually):
- Perception: produces the 8 “food readings” (and later water depth cues, opacity, etc.)
- Cognition: chooses a direction by combining:
	- perceived promise (e.g., “food is higher to the NE”)
	- learned expectation (e.g., “NE usually hurts me; maybe it’s deep water”) 
	- current reserves (risk tolerance)
- Motion: turns that choice into a move delta.
- After the move resolves, Cognition updates the memory table using the error.

### A tiny bit of context conditioning (optional next step)
If a single 8-value table is too blunt, the next-smallest upgrade is to have *two* tables, keyed by one obvious context bit:
- day vs night (because `SolarFlux` changes strategy)

So:
- `ExpectedDeltaE_Day[dir]`
- `ExpectedDeltaE_Night[dir]`

Still dead-simple, but it captures “bask by day, hunt by night” tendencies.

### Where “water depth perception limits” fits
Your “oops it’s deeper than I can perceive” becomes a learning driver automatically:
- Perception underestimates risk.
- The move produces a large negative `actualDeltaE`.
- Error becomes strongly negative.
- The chosen direction’s expectation drops.
- Over time, the agent learns caution *without ever being told* “water is bad”.

### Memory vs DNA (important separation)
- DNA can set learning-related parameters (without hardcoding behavior):
	- `learningRate` (how fast expectations change)
	- “exploration” tendency (how often it ignores its current best guess)
	- perception noise/range (what evidence it gets)
- Memory is what changes within a lifetime.

This gives you two timescales:
- evolution invents new capabilities (new genes / descendants)
- learning tunes behavior inside the capability envelope (parameters + memory)


-----------
My selected copy/paste/edits from conversation, not generated notes. Do this:

## Two-phase step
Keep genes stateless, but add an explicit second phase in the sim loop:

1. Decide phase (what you already do)

- run gene slots in order (E, P, M, C…)
- produce a request (move dir, eat target, etc.)
- store “what I tried” in agent persistent state (or in a per-step action record)

2. Apply phase (already exists)
- sim applies the request and computes actual outcomes (net energy delta, traversal penalty, etc.)

3. Learn phase (new, but tiny)
- call a learning update that reads:
  - the attempted action
  - the observed outcome (e.g., actualDeltaE)
  - the agent’s persistent memory table (e.g., ExpectedDeltaE[dir])
- writes back updated expectations

This “learn phase” does not need to be a gene. It’s just part of the simulator’s agent-step bookkeeping, using the same “dumb, local, indifferent” philosophy.

Why this is a good match:

Genes stay pure/stateless.
Learning is naturally post-outcome.
You avoid inventing “a first gene” that’s semantically weird.



## Where the memory should live (with stateless genes)
Memory has to be persistent per agent, so it belongs in the agent state, not in the gene class.

Practically:

- Put a Memory record on the agent (or inside the agent’s Cognition state).
- Start with something tiny like ExpectedDeltaE[8] (optionally day/night split).
- Your genes read/write that record; the gene class remains stateless.

This also lines up with your “volatile section” idea:

- volatile = scratchpad for one tick (perception readings, chosen direction, etc.)
- persistent = reserves + long-lived traits + memory tables

Direct answer to “do I need a gene that executes first?”
Not necessary, and I’d avoid it as a primary design because it mixes concerns (“learning about last action” vs “deciding next action”). If you want no sim changes, the one-tick-delayed approach is the closest, but conceptually it’s still “a post-outcome update”, just delayed.

If you want one concrete recommendation: implement Option 1 (two-phase: decide → apply → learn), and in V1 only Cognition participates in the learn phase.

One clarifying question that will let me be more concrete: when the sim “applies the request”, do you already compute a single net actualDeltaE (including traversal + absorption/food), or are those components still separate? Either is fine; it just affects what the learning update reads.


