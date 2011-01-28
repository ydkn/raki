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

class RakiSyntax::TableNode < RakiSyntax::Node

  def to_html context
    out = "<table class=\"wikitable\">"
    out += "<tr>" + first_row.to_html(context) + "</tr>"
    other_rows.elements.each do |row|
      out += "<tr>" + row.to_html(context) + "</tr>"
    end
    out += "</table>"
  end

end


class RakiSyntax::TableRowNode < RakiSyntax::Node

  def to_html context
    out = ''
    
    is_head_row = !head_row.text_value.empty?
    cells.elements.each do |cell|
      if is_head_row || !cell.head.text_value.empty?
        out += "<th>" + cell.data.to_html(context) + "</th>"
      else
        out += "<td>" + cell.data.to_html(context) + "</td>"
      end
    end
    
    out
  end

end
