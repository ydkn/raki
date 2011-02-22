# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab & Martin Sigloch
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

Raki::Plugin.register :for do
  
  name 'for loop'
  description 'repeat body for all values in first line'
  url 'http://github.com/ydkn/raki'
  author 'Martin Sigloch'
  version '0.1'
  
  execute do
    raise unless body =~ /\w+\s+in\s+\w[\w\s]+\n.+/
    command = body.lines.to_a[0].strip
    template = body.lines.to_a[1..-1].join
    variable = command.split(/\s+in\s+/)[0]
    values   = command.split(/\s+in\s+/)[1].split
    raise unless variable and values and body
    out = ""
    values.each do |val|
      out += template.gsub("$#{variable}", val)
    end
    render :inline => "#{parse context[:page].namespace, out}"
  end

end
