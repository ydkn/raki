# Raki - extensible rails-based wiki
# Copyright (C) 2011 Florian Schwab & Martin Sigloch
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

Raki::Plugin.register :osm do
  
  name 'OSM plugin'
  description 'Plugin embed OSM maps into wiki pages'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'
  
  execute do
    BOX_FACTOR = 0.0035
    
    lat, lon = body.strip.split ',', 2
    lat = lat.strip.to_f
    lon = lon.strip.to_f
    
    @bbox = "#{lon-BOX_FACTOR},#{lat-BOX_FACTOR},#{lon+BOX_FACTOR},#{lat+BOX_FACTOR}"
  end
  
end