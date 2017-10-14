# Copyright (C) 2015  onox
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Position and offset of the start point of a tiedown. The position is on
# the surface of the fuselage or wing.
var point_coords = {
    left: {
        x:  2.8000,
        y: -4.0000,
        z: -0.4500,
        offset: 90.0
    },

    right: {
        x:  2.8000,
        y:  4.0000,
        z: -0.4500,
        offset: -90.0
    },

    'tail-left': {
        x:  6.4800,
        y: -0.2600,
        z: -0.4220,
        offset: 90.0
    },

    'tail-right': {
        x:  6.4800,
        y:  0.2600,
        z: -0.4220,
        offset: -90.0
    },
};

# Values must be the same as in Models/p51d-jw-jsbsim.xml
var model_offsets_pitch_deg = 0.0;
var model_offsets_z_m = 0.0;

var TiedownPositionUpdater = {

    new: func (name) {
        var m = {
            parents: [TiedownPositionUpdater]
        };
        m.loop = updateloop.UpdateLoop.new(components: [m], update_period: 0.0, enable: 0);
        m.name = name;
        return m;
    },

    enable: func {
        me.loop.reset();
        me.loop.enable();
    },

    disable: func {
        me.loop.disable();
    },

    enable_or_disable: func (enable) {
        if (enable)
            me.enable();
        else
            me.disable();
    },

    reset: func {
        me.end_point = geo.aircraft_position();
        var heading = getprop("/orientation/heading-deg");

        var x = getprop("/aircraft/tiedowns", me.name, "x");
        var y = getprop("/aircraft/tiedowns", me.name, "y");

        # Set position of end point
        var course = heading + geo.normdeg(math_ext.atan(y, x));
        var distance = math.sqrt(math.pow(x, 2) + math.pow(y, 2));
        me.end_point.apply_course_distance(course, distance);

        # Set altitude of end point
        var elev_m = geo.elevation(me.end_point.lat(), me.end_point.lon());
        me.end_point.set_alt(elev_m or getprop("/position/ground-elev-m"));

        me.init_ref_length();
    },

    init_ref_length: func {
        # Call update() to compute initial length
        me.update(0);
        var length = getprop("/aircraft/tiedowns", me.name, "length-m");
        setprop("/aircraft/tiedowns", me.name, "ref-length-m", length);
    },

    update: func (dt) {
        var point = point_coords[me.name];

        var start_x = point.x;
        var start_y = point.y;
        var start_z = point.z + model_offsets_z_m;

        var roll_deg  = getprop("/orientation/roll-deg");
        var pitch_deg = getprop("/orientation/pitch-deg") + model_offsets_pitch_deg;
        var heading   = getprop("/orientation/heading-deg");

        # Compute the actual position of the start of the tiedown
        var (start_point_2d, start_point) = math_ext.get_point(start_x, start_y, start_z, roll_deg, pitch_deg, heading);

        var (yaw, pitch, distance) = math_ext.get_yaw_pitch_distance_inert(start_point_2d, start_point, me.end_point, heading);
        (yaw, pitch) = math_ext.get_yaw_pitch_body(roll_deg, pitch_deg, yaw, pitch, point.offset);

        setprop("/aircraft/tiedowns", me.name, "heading-deg", yaw);
        setprop("/aircraft/tiedowns", me.name, "pitch-deg", pitch);
        setprop("/aircraft/tiedowns", me.name, "length-m", distance);
    },

};

var tiedown_left_updater  = TiedownPositionUpdater.new("left");
var tiedown_right_updater = TiedownPositionUpdater.new("right");
var tiedown_tail_left_updater  = TiedownPositionUpdater.new("tail-left");
var tiedown_tail_right_updater  = TiedownPositionUpdater.new("tail-right");

setlistener("/sim/signals/fdm-initialized", func {
    setlistener("/aircraft/securing/left-tiedown-visible", func (node) {
        tiedown_left_updater.enable_or_disable(node.getValue());
    }, 1, 0);

    setlistener("/aircraft/securing/right-tiedown-visible", func (node) {
        tiedown_right_updater.enable_or_disable(node.getValue());
    }, 1, 0);

    setlistener("/aircraft/securing/tail-left-tiedown-visible", func (node) {
        tiedown_tail_left_updater.enable_or_disable(node.getValue());
    }, 1, 0);

    setlistener("/aircraft/securing/tail-right-tiedown-visible", func (node) {
        tiedown_tail_right_updater.enable_or_disable(node.getValue());
    }, 1, 0);

    setlistener("/fdm/jsbsim/damage/repairing", func (node) {
        # When the aircraft has been repaired (value is switched back
        # to 0), compute the new initial length of the tiedowns
        if (!node.getValue()) {
            tiedown_left_updater.init_ref_length();
            tiedown_right_updater.init_ref_length();
            tiedown_tail_left_updater.init_ref_length();
            tiedown_tail_right_updater.init_ref_length();
        }
    }, 0, 0);
});