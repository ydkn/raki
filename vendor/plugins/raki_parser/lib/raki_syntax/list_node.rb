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

class RakiSyntax::ListNode < RakiSyntax::Node

  def to_html context

    items = [first_item]
    other_items.elements.each do |other|
      items += [other.item]
    end

    @lists = []
    out = ''

    items.each do |item|
      out += adapt item.level.text_value.length + 1, item.type.text_value
      out += '<li>'
      out += item.text.to_html context
    end
    out += adapt 0, ''
  end

  private

  def adapt level, type
    diff = level - @lists.size
    parameter = ''
    out = ''

    if type == '#'
      type = 'ol'
    elsif type == '*'
      type = 'ul'
    elsif type == '-'
      type = 'ul'
      parameter = 'class="line"'
    else
      type = ''
    end

    if diff > 0
      (1..diff).each do
        out += "\n" unless @lists.empty?
        if parameter.empty?
          out += "<#{type}>"
        else
          out +=  "<#{type} #{parameter}>"
        end
        @lists = @lists << type
      end
    elsif diff < 0
      (diff..-1).each do
        out += "</li></#{@lists.slice!(-1)}>"
      end
      out += "</li>" unless @lists.empty?
    else
      out += "</li>"
    end

    if type != @lists[-1] && level != 0
      out += "</#{@lists.slice!(-1)}>"
      out += "<#{type}>"
      @lists = @lists << type
    end
    out
  end

end
