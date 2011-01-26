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

module TOCPluginHelper
  
  def render_section section
    output = ''
    
    section.each do |s|
      output += "<li><a href=\"##{s[:anchor]}\">#{h s[:title]}</a></li>" if s[:anchor] && s[:title]
      output += render_section s[:subsections] if s[:subsections]
    end
    
    "<ul>#{output}</ul>"
  end
  
end
