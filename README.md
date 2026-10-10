# handplow

## Purpose

Design a scaled-down, 3D-printable demo of the seed metering mechanism from the
single-wheel seeder in [WheelHoe.txt](WheelHoe.txt), modeled in OpenSCAD.

- **Focus:** the seed metering wheel (seed plate). If we go with a drum-style
  meter instead, the drum replaces the wheel.
- **Goal:** show how the mechanism works: ground wheel turns, the meter picks up
  seeds one at a time, and drops them down the tube.
- **Build:** print the parts separately and assemble them.
- **Out of scope for now:** full-size steel frame, handles, plow and cultivator
  attachments.

## Plan

1. **Phase 1, meter unit (current):** hopper, seed plate, floor, and a
   right-angle drive turned by a hand crank. Proves that the plate picks up one
   seed per cell and drops it.
2. **Phase 2, drive train:** ground wheel at 1:4 scale (about 98 mm), a belt or
   printed chain from the wheel to the meter's shaft, a furrow shoe and a drop tube.

The meter is **not** scaled down, because seeds don't scale. It's sized for real
seed (popcorn or small dried peas by default). `scale_ratio` in
[meter_lib.scad](scad/meter_lib.scad) only sets the wheel and frame size, so
switching between 1:3 and 1:4 is a one-line change.

## How it works

The axle turns a spur pinion under the floor. The pinion meshes with crown teeth
on the underside of the seed plate, so the plate turns flat on the floor (24:24,
one plate turn per axle turn). Seeds in the hopper drop into the plate's cells.
A cutoff block in the hopper wipes off extra seed, so only the seed sitting in
each cell is carried over the drop hole, where it falls out through the spout.

## Files

- [scad/meter_lib.scad](scad/meter_lib.scad): all parameters and part modules
- [scad/meter_assembly.scad](scad/meter_assembly.scad): assembly view. Use
  View > Animate (FPS 10, Steps 72) to watch it turn; set `cutaway` or
  `explode` to look inside
- [scad/print_parts.scad](scad/print_parts.scad): each part in print
  orientation; set `part`, render (F6), export STL
- `stl/`: exported STLs (not tracked in git; regenerate from print_parts.scad)

## Printing (PLA, 0.4 mm nozzle)

| Part   | Orientation               | Supports | Notes |
|--------|---------------------------|----------|-------|
| plate  | top face down             | none     | crown teeth print upward |
| base   | upside down (floor on bed)| none     | about 120 x 120 x 57 mm |
| hopper | upright                   | build plate only | supports needed under the cutoff block |
| pinion | gear face down            | none     | |
| crank  | flat                      | none     | |
| collar | flat                      | none     | |

All parts fit a 280 x 240 mm bed; the hopper is the largest at 172 mm across.

## Hardware

- 8 mm rod (smooth or M8 threaded), about 150 mm long
- 2 x 608 bearings (8 x 22 x 7 mm, skateboard bearings), pressed into the base
- 3 x M3 set screws (M3 x 8) and 3 x M3 nuts: pinion, crank, collar
- Optional: about 15 cm of vinyl tube with 15 mm ID to push over the spout

## Tuning

- **Bearing fit:** `bearing_fit` (22.25 mm). Increase it if the 608s won't press in.
- **Seed size:** `cell_d` and `plate_t`. Cells should be about 1 mm larger than
  the seed, and the plate about one seed thick. `n_cells` sets seeds per turn.
- **Gears:** the crown teeth are straight, which only approximates a true face
  gear. That's why `backlash` (0.8) and `tip_trim` (0.6) are generous and the
  face is narrow. With these values the pinion and plate don't collide anywhere
  in a full tooth pitch (checked in CGAL).
