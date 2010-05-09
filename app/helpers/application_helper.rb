# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
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

module ApplicationHelper

  def format(parser, text)
    Raki.parser(parser).parse(text)
  end

  def plugin_stylesheets
    stylesheets = []
    Raki::Plugin.stylesheets.each do |stylesheet|
      stylesheets << stylesheet_link_tag(stylesheet[:url], stylesheet[:options])
    end
    stylesheets.join("")
  end
  
  KILOBYTE = 1024.0
  MEGABYTE = 1048576.0
  GIGABYTE = 1073741824.0

  def format_size(size)
    size = size.to_f
    case
      when size == 1
        out = "1 Byte"
      when size < KILOBYTE
        out = "#{size} Bytes"
      when size < MEGABYTE
        out = "%.2f KB" % (size/KILOBYTE)
      when size < GIGABYTE
        out = "%.2f MB" % (size/MEGABYTE)
      else
        out = "%.2f GB" % (size/GIGABYTE)
    end
    out
  end

end
