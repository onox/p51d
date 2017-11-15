# Copyright (C) 2016  onox
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

setlistener("/aircraft/afcs/locks/rudder", func (node) {
    if (node.getBoolValue())
        logger.screen.green("Auto rudder enabled");
    else
        logger.screen.red("Auto rudder disabled");
}, 0, 0);

setlistener("/aircraft/afcs/locks/wings-level-vs-hold", func (node) {
    if (!node.getBoolValue())
        logger.screen.red("Wing leveler and V/S hold disabled");
}, 0, 0);

setlistener("/aircraft/afcs/target/vs-fpm", func (node) {
    if (getprop("/aircraft/afcs/locks/wings-level-vs-hold")) {
        var format = "Wing leveler and V/S (%.0f fpm) hold enabled";
        logger.screen.green(sprintf(format, node.getValue()));
    }
}, 0, 1);

setlistener("/aircraft/afcs/active/takeoff", func (node) {
    if (node.getBoolValue())
        logger.screen.green("Automatic takeoff activated");
    else
        logger.screen.red("Automatic takeoff cancelled");
}, 0, 0);

setlistener("/aircraft/brakes/parking-cmd", func (node) {
    # Unset internal command if set
    if (node.getBoolValue())
        node.setBoolValue(0);
}, 0, 0);

setlistener("/aircraft/brakes/parking-set", func (node) {
    if (node.getBoolValue())
        logger.screen.green("Parking brakes enabled (tap brakes to release)");
    else
        logger.screen.red("Parking brakes released");
}, 0, 0);
