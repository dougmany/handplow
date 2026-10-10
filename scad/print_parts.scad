// Seed meter demo: printable parts, each laid out in print orientation.
// Pick one with `part`, then F6 and File > Export > STL.
//
//   "plate"   top face on the bed, no supports
//   "base"    floor top on the bed (upside down), no supports
//   "hopper"  upright; enable supports from the build plate for the
//             cutoff block over the drop hole
//   "pinion"  gear face down, no supports
//   "crank"   flat, no supports
//   "collar"  flat, no supports
include <meter_lib.scad>

part = "plate";

if (part == "plate")
    translate([0, 0, plate_t]) rotate([180, 0, 0]) seed_plate();
else if (part == "base")
    rotate([180, 0, 0]) base();
else if (part == "hopper")
    translate([0, 0, hopper_recess]) hopper();
else if (part == "pinion")
    pinion_local();
else if (part == "crank")
    crank_local();
else if (part == "collar")
    collar_local();
