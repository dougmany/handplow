// Seed meter demo: assembly view.
// View > Animate, then set FPS 10 and Steps 72 to watch it turn.
include <meter_lib.scad>

explode = 0;          // try 30 to pull the parts apart
show_hopper = true;
cutaway = false;      // slice away the front half to see the plate and pinion

a = $t * 360;                         // axle angle
plate_a = -a * pinion_n / crown_n;    // plate turns clockwise seen from above

module scene() {
    color("burlywood") base();
    color("silver") axle_rod();
    color("orange") pinion(a);
    color("seagreen") translate([0, 0, explode]) rotate(plate_a) seed_plate();
    if (show_hopper)
        color("lightskyblue", 0.6) translate([0, 0, 2.5 * explode]) hopper();
    color("tomato") translate([0, floor_half + 1 + explode, axle_z])
        rotate([0, a, 0]) rotate([-90, 0, 0]) crank_local();
    color("tomato") translate([0, -floor_half - 1 - explode, axle_z])
        rotate([0, a, 0]) rotate([90, 0, 0]) collar_local();
}

if (cutaway)
    difference() {
        scene();
        translate([-200, -400, -200]) cube([400, 400, 400]);
    }
else
    scene();
