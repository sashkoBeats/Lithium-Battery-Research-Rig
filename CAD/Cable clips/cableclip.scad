/*  cable management clip
    2017-10-13 Russell Salerno
    
    v2 with more automated parameter generation
    notes: open base is preferable as it makes the clamp more flexible & crack-resistant
    
*/


//Clip parameters

// [Distance clip extends from the wall]
depth = 65.5;

// [Height of arms]
height = 18.0;

// [Width of clip, cannot exceed depth]
width = 42.0;

// [Jaw thickness at top]
jaws = 9.0;

// [Space between jaws]
throat = 2.25;

// [Arm thickness]
side_thickness = 3.5;

// [Base thickness]
base_thickness = 5.0;

// [Distance each side wing extends from the arms]
base_sides = 10;

// [Leave at 0 for default ratio of 0.35*height]
base_height_ratio = 0;

// [Minkowski radius for edges]
radius = 2.25;

//Open or closed base? (choose closed if num_holes=1 or 3)
base_type = "open";  // [open, closed]

//Number of screw holes
num_holes = 2;      // [0, 1, 2, 3]

//Hole diameter
hole_diameter = 4;  // [0:10]

//Test render
test_render = true; // [true, false]

module null() {}

//sample sizes
//small
/*
depth = 28;
height = 10.0;
width = 15.0;
jaws = 4.0;
throat = 1.0;
side_thickness = 1.75;
base_thickness = 3.0;
base_sides = 8;
base_height_ratio = 0.25;        // [leave 0 for default]
radius = 0.75;
*/

//small/tall 
/* 
depth = 34;
height = 10.0;
width = 15.0;
jaws = 4.0;
throat = 1.0;
side_thickness = 2.0;
base_thickness = 3.0;
base_sides = 8;
base_height_ratio = 0;        // [leave 0 for default]
radius = 0.75;
*/

//medium
/*
depth = 38;
height = 12.0;
width = 25.0;
jaws = 5.0;
throat = 2.0;
side_thickness = 2.25;
base_thickness = 3.5;
base_sides = 9;
base_height_ratio = 0;        // [leave 0 for default]
radius = 0.95;
*/

//large (original size)
/*
depth = 65.5;
height = 18.0;
width = 42.0;
jaws = 9.0;
throat = 2.25;
side_thickness = 3.5;
base_thickness = 5.0;
base_sides = 10;
base_height_ratio = 0;        // [leave 0 for default]
radius = 2.25;
*/

$fn=60;
minkr=test_render ? 0:radius;   //minkowski takes a while to render, set to zero for testing

clipy=depth-minkr*2;
//clipx=width-minkr*2;
clipx=(width > depth)? clipy:width-minkr*2;     // width can't exceed depth
clipz=height-minkr*2;
clipthk=side_thickness-minkr;
clipjaws=jaws-minkr;
clipbase=base_thickness-minkr;

//throata1=22;
//throata2=25;
throata1=12*(depth/width);
throata2=10*(depth/(width-2*clipthk));
throaty=9/11*jaws;
throatx=throat+2*minkr;

basez=base_sides;
basey=(base_height_ratio == 0)? depth*0.35:depth*base_height_ratio;
baseholed=hole_diameter;

module throat() {
    translate([clipx/2, clipy-clipx/2, 0]) polygon([
        [clipx/2*-sin(throata1), clipx/2*cos(throata1)],
        [clipx/2, clipy],
        [clipx/2*sin(throata1), clipx/2*cos(throata1)], 
        [throatx/2, -throaty+clipx/2],
        [(clipx-clipthk*2)/2*sin(throata2), clipx/2*cos(throata2)-clipjaws-clipthk],
        [(clipx-clipthk*2)/2*-sin(throata2), clipx/2*cos(throata2)-clipjaws-clipthk],
        [-throatx/2, -throaty+clipx/2]]);
}

module base() {
    translate([0, 0, -basez]) linear_extrude(clipz+2*basez) difference() {
        square([clipx, basey]);
        translate([clipthk, clipbase, 0]) square([clipx-clipthk*2, basey-clipbase]);
    }
}

module holes() {
    translate([-minkr, 0, -minkr]) {

        if (num_holes == 1 || num_holes == 3) {
            translate([clipx/2+minkr, base_thickness, height/2]) rotate([90,0,0]) cylinder(d=baseholed, h=base_thickness+minkr);        // hole 1 of 1 hole base
         }

        if (num_holes == 2 || num_holes == 3){
            translate([clipx/2+minkr, base_thickness, -basez/2]) rotate([90,0,0]) cylinder(d=baseholed, h=base_thickness+minkr);        // hole 1 of 2 hole base
            translate([clipx/2+minkr, base_thickness, height+basez/2]) rotate([90,0,0]) cylinder(d=baseholed, h=base_thickness+minkr);  // hole 2 of 2 hole base
        }

        if (base_type == "open") {
            translate([side_thickness+minkr, 0, 0]) linear_extrude(height) square([clipx-clipthk*2-minkr*2, base_thickness]);   // hole for open base
        }
        translate([0, -2*minkr, -basez]) linear_extrude(clipz+2*basez+2*minkr) square([clipx+2*minkr, 2*minkr]);            // flatten the bottom
    }
}

module mainshape() {
    linear_extrude(clipz) difference() {
        hull() {
            square([clipx, 1]);
            translate([clipx/2, clipy-clipx/2, 0]) circle(d=clipx);
        }
        hull() {
            translate([clipthk, clipbase, 0]) square([clipx-clipthk*2, 1]);
            translate([clipx/2, clipy-clipjaws-(clipx-clipthk)/2, 0]) circle(d=clipx-clipthk*2);
        }
        throat();
    }
    base();
}


rotate ([90, 0, 0]) difference() {
    minkowski() {
        mainshape();
        sphere(r=minkr);
    }
    holes();
}


