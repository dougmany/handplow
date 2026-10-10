// Seed meter demo: shared parameters and part modules.
// Units: mm. Assembly origin: center of the seed plate, on the floor's top
// surface. +Y runs along the axle (crank at +Y), +Z is up, and the drop hole
// sits at -X. The plate turns clockwise seen from above.
//
// The meter is sized for real seeds, so it is NOT scaled. `scale_ratio` only
// applies to the ground wheel and frame (phase 2).

$fa = 4;
$fs = 0.4;

// ---------- Scale (phase 2: wheel and frame) ----------
scale_ratio = 1/4;
full_wheel_d = 15.5 * 25.4;
wheel_d = full_wheel_d * scale_ratio;

// ---------- Seed plate ----------
seed_name = "popcorn / small peas";
cell_d = 8.5;        // cell diameter: seed size + ~1 mm
plate_t = 6;         // plate thickness: about one seed deep
n_cells = 8;
cell_r = 39;         // radius of the cell circle
plate_r = 46;
pivot_d = 8;         // pivot stub under the plate
pivot_len = 4;

// ---------- Right-angle drive: crown teeth on plate, spur pinion on axle ----------
gear_m = 2;          // module
crown_n = 24;        // teeth on the plate's crown
pinion_n = 24;       // teeth on the pinion (24/24 = 1 plate turn per axle turn)
pressure_angle = 20;
backlash = 0.8;      // total; straight crown teeth need extra clearance
tip_trim = 0.6;      // tip relief: shortens the teeth on both gears
crown_rp = crown_n * gear_m / 2;
pinion_rp = pinion_n * gear_m / 2;
gear_add = gear_m;
gear_ded = 1.25 * gear_m;
crown_face = 4;       // keep narrow: straight teeth only fit near the pitch radius
crown_in = crown_rp - crown_face / 2;
crown_out = crown_rp + crown_face / 2;
pinion_face = crown_face + 1;
pinion_y0 = crown_in - 0.5;          // inner face of the pinion along the axle

// ---------- Axle and hardware ----------
axle_d = 8;                          // 8 mm rod or M8 threaded rod
axle_clear = 8.3;
axle_z = -gear_ded - pinion_rp;      // pinion pitch circle touches crown pitch line
bearing_d = 22;                      // 608 bearing
bearing_w = 7;
bearing_fit = 22.25;                 // press fit; tune for your printer
m3_clear = 3.3;
m3_nut_af = 5.8;                     // across flats, with clearance
m3_nut_t = 2.8;

// ---------- Base (floor + cheeks) ----------
floor_t = 8;
floor_half = 60;
groove_in = crown_in - 2;
groove_out = crown_out + 2.5;
groove_depth = gear_ded + gear_add + 0.8;
cheek_t = 10;
cheek_y = floor_half - cheek_t;      // inner face of each cheek
cheek_half_x = 45;
feet_z = axle_z - (pinion_rp + gear_add) - 4;
drop_angle = 180;
drop_d = cell_d + 1;
spout_id = 11;
spout_od = 15;

// ---------- Hopper ----------
hopper_in_r = plate_r + 1;
hopper_ring_r = hopper_in_r + 8;
hopper_recess = 2;                   // hopper sits in a recess in the floor
hopper_straight = plate_t + 3;
hopper_h = 45;
hopper_wall = 3;
hopper_top_r = hopper_in_r + (hopper_h - hopper_straight);   // 45-degree walls
key_w = 8;
key_len = 4;
cutoff_gap = 0.6;                    // clearance between plate top and cutoff
cutoff_span = [drop_angle - 20, 55]; // start angle, sweep (cells arrive from above)

// =====================================================================
// Helpers
// =====================================================================

function inv_pt(rb, t) =
    let(td = t * 180 / PI)
    rb * [cos(td) + t * sin(td), sin(td) - t * cos(td)];

// 2D involute spur gear, one tooth centered on +X before `phase`.
module spur_2d(n, m, pa, bl, phase = 0) {
    rp = n * m / 2;
    rb = rp * cos(pa);
    ra = rp + m - tip_trim;
    rf = rp - 1.25 * m;
    s = PI * m / 2 - bl / 2;
    tp = sqrt(pow(rp / rb, 2) - 1);
    phi_p = (tp - atan(tp) * PI / 180) * 180 / PI;
    th0 = s / (2 * rp) * 180 / PI + phi_p;
    ta = sqrt(pow(ra / rb, 2) - 1);
    steps = 12;
    flank_a = [for (i = [0:steps])
        let(p = inv_pt(rb, ta * i / steps), q = [p[0], -p[1]])
        [q[0] * cos(th0) - q[1] * sin(th0), q[0] * sin(th0) + q[1] * cos(th0)]];
    flank_b = [for (p = flank_a) [p[0], -p[1]]];
    tooth = concat([[0, 0]], flank_b,
                   [for (i = [len(flank_a) - 1:-1:0]) flank_a[i]]);
    rotate(phase)
    intersection() {
        circle(r = ra, $fn = n * 8);
        union() {
            circle(r = rf, $fn = n * 8);
            for (k = [0:n - 1]) rotate(k * 360 / n) polygon(tooth);
        }
    }
}

// Teardrop hole along +Y with its point toward -Z (prints point-up when
// the base is printed upside down).
module teardrop_y(d, len) {
    rotate([-90, 0, 0]) linear_extrude(len)
        union() { circle(d = d); rotate(45) square(d / 2); }
}

// Radial M3 set screw with a nut slot open to the hub end face.
// Hub axis is Z, hub spans z = 0..hub_len; screw points along +X.
module set_screw_cut(bore_d, hub_r, hub_len) {
    zm = hub_len / 2;
    translate([0, 0, zm]) rotate([0, 90, 0]) cylinder(d = m3_clear, h = hub_r + 1);
    nx = bore_d / 2 + (hub_r - bore_d / 2) / 2;
    hull() {
        translate([nx, 0, zm]) rotate([0, 90, 0])
            cylinder(d = m3_nut_af / cos(30), h = m3_nut_t, center = true, $fn = 6);
        translate([nx, 0, hub_len + 1]) rotate([0, 90, 0])
            cylinder(d = m3_nut_af / cos(30), h = m3_nut_t, center = true, $fn = 6);
    }
}

// =====================================================================
// Parts (in assembly position unless noted)
// =====================================================================

// Seed plate. z = 0 is its underside.
module seed_plate() {
    pitch = PI * gear_m;
    gap_pitch = pitch / 2 + backlash / 2;      // constant-width tooth spaces
    tn = tan(pressure_angle);
    // Gap profile in (tangential, z); pitch line at z = -gear_ded.
    gap = [
        [-(gap_pitch / 2 - gear_ded * tn), 0],
        [ (gap_pitch / 2 - gear_ded * tn), 0],
        [ (gap_pitch / 2 + (gear_add + 1.5) * tn), -(gear_ded + gear_add + 1.5)],
        [-(gap_pitch / 2 + (gear_add + 1.5) * tn), -(gear_ded + gear_add + 1.5)]];
    difference() {
        union() {
            cylinder(r = plate_r, h = plate_t);
            // crown ring
            translate([0, 0, -(gear_ded + gear_add - tip_trim)])
                difference() {
                    cylinder(r = crown_out, h = gear_ded + gear_add - tip_trim + 1);
                    translate([0, 0, -1]) cylinder(r = crown_in, h = 10);
                }
            translate([0, 0, -pivot_len]) cylinder(d = pivot_d, h = pivot_len + 0.01);
        }
        // tooth spaces: gap centered on +Y at zero rotation
        for (k = [0:crown_n - 1]) rotate(90 + k * 360 / crown_n)
            translate([crown_in - 1, 0, 0]) rotate([90, 0, 90])
                linear_extrude(crown_face + 2) polygon(gap);
        // seed cells
        for (k = [0:n_cells - 1]) rotate(k * 360 / n_cells)
            translate([cell_r, 0, -1]) cylinder(d = cell_d, h = plate_t + 2);
        // finger holes for lifting the plate out
        for (a = [45, 225]) rotate(a) translate([crown_out + 3.5, 0, -1])
            cylinder(d = 5, h = plate_t + 2);
    }
}

// Pinion, local frame: axis Z, gear face z = 0..pinion_face, hub above.
pinion_hub_r = 9;
pinion_hub_len = 8;
module pinion_local() {
    difference() {
        union() {
            linear_extrude(pinion_face)
                spur_2d(pinion_n, gear_m, pressure_angle, backlash, phase = -90);
            cylinder(r = pinion_hub_r, h = pinion_face + pinion_hub_len);
        }
        translate([0, 0, -1]) cylinder(d = axle_clear, h = 50);
        translate([0, 0, pinion_face]) set_screw_cut(axle_clear, pinion_hub_r, pinion_hub_len);
    }
}

module pinion(a = 0) {
    translate([0, 0, axle_z]) rotate([0, a, 0])
        translate([0, pinion_y0, 0]) rotate([-90, 0, 0]) pinion_local();
}

// Floor, cheeks and spout as one printed part.
module base() {
    difference() {
        union() {
            translate([-floor_half, -floor_half, -floor_t])
                cube([2 * floor_half, 2 * floor_half, floor_t]);
            for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0])
                translate([-cheek_half_x, cheek_y, feet_z])
                    cube([2 * cheek_half_x, cheek_t, -feet_z]);
            // spout under the drop hole
            rotate(drop_angle) translate([cell_r, 0, feet_z + 6])
                cylinder(d = spout_od, h = -feet_z - 6);
        }
        // groove for the crown teeth
        translate([0, 0, -groove_depth])
            difference() {
                cylinder(r = groove_out, h = groove_depth + 1);
                translate([0, 0, -1]) cylinder(r = groove_in, h = groove_depth + 3);
            }
        // clearance for the pinion where it reaches up into the groove
        translate([0, pinion_y0 - 0.75, axle_z]) rotate([-90, 0, 0])
            cylinder(r = pinion_rp + gear_add + 1, h = pinion_face + 1.5);
        // pivot hole
        translate([0, 0, -pivot_len - 1]) cylinder(d = pivot_d + 0.6, h = pivot_len + 2);
        // drop hole and spout bore
        rotate(drop_angle) translate([cell_r, 0, feet_z]) {
            cylinder(d = spout_id, h = -feet_z - floor_t + 0.01);
            translate([0, 0, -feet_z - floor_t]) cylinder(d1 = spout_id, d2 = drop_d, h = floor_t + 1);
        }
        // hopper recess with key at +X
        translate([0, 0, -hopper_recess]) {
            difference() {
                cylinder(r = hopper_ring_r + 0.4, h = hopper_recess + 1);
                translate([0, 0, -1]) cylinder(r = hopper_in_r - 0.4, h = hopper_recess + 3);
            }
            translate([hopper_ring_r - 1, -(key_w + 0.6) / 2, 0])
                cube([key_len + 1.4, key_w + 0.6, hopper_recess + 1]);
        }
        // axle bores and bearing pockets
        for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) {
            translate([0, cheek_y - 1, axle_z]) teardrop_y(12, cheek_t + 2);
            translate([0, floor_half - bearing_w - 0.2, axle_z]) teardrop_y(bearing_fit, bearing_w + 1);
        }
        // lighten the cheeks
        for (s = [-1, 1]) mirror([0, s < 0 ? 1 : 0, 0]) for (x = [-30, 30])
            translate([x, cheek_y - 1, (feet_z - floor_t) / 2 - 2]) rotate([-90, 0, 0])
                cylinder(d = 16, h = cheek_t + 2);
    }
}

// Hopper. Sits in the floor recess; bottom of the ring at z = -hopper_recess.
module hopper() {
    z1 = hopper_h - (hopper_top_r + hopper_wall - hopper_ring_r);
    z0 = plate_t + cutoff_gap;
    union() {
        rotate_extrude() polygon([
            [hopper_in_r, -hopper_recess],
            [hopper_ring_r, -hopper_recess],
            [hopper_ring_r, z1],
            [hopper_top_r + hopper_wall, hopper_h],
            [hopper_top_r, hopper_h],
            [hopper_in_r, hopper_straight]]);
        // key
        translate([hopper_ring_r - 1, -key_w / 2, -hopper_recess])
            cube([key_len + 1, key_w, hopper_recess + 4]);
        // cutoff block over the drop hole: only seeds sitting in cells pass under
        rotate(cutoff_span[0]) rotate_extrude(angle = cutoff_span[1]) polygon([
            [cell_r - cell_d / 2 - 3, z0],
            [hopper_in_r + 1, z0],
            [hopper_in_r + 1, hopper_straight],
            [hopper_in_r + 11, hopper_straight + 10],
            [cell_r - cell_d / 2 - 3, z0 + 6]]);
    }
}

// Crank, local frame: hub axis Z.
crank_arm = 40;
module crank_local() {
    hub_r = 10;
    hub_len = 12;
    difference() {
        union() {
            cylinder(r = hub_r, h = hub_len);
            hull() {
                cylinder(r = hub_r, h = 7);
                translate([crank_arm, 0, 0]) cylinder(r = 7, h = 7);
            }
            translate([crank_arm, 0, 0]) cylinder(d = 10, h = 7 + 28);
        }
        translate([0, 0, -1]) cylinder(d = axle_clear, h = hub_len + 2);
        rotate(180) set_screw_cut(axle_clear, hub_r, hub_len);
    }
}

// Shaft collar, local frame: axis Z.
module collar_local() {
    difference() {
        cylinder(r = 10, h = 10);
        translate([0, 0, -1]) cylinder(d = axle_clear, h = 12);
        set_screw_cut(axle_clear, 10, 10);
    }
}

module axle_rod() {
    translate([0, -floor_half - 12, axle_z]) rotate([-90, 0, 0])
        cylinder(d = axle_d, h = 2 * floor_half + 12 + 16);
}
