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

require 'htmlentities'

module HTMLSyntax
  def to_html
    @@coder = HTMLEntities.new unless defined? @@coder
    output = ''
    unless elements.nil?
      elements.each do |e|
        unless e.elements.nil?
          output += e.to_html
        else
          output += @@coder.encode e.text_value
        end
      end
    end
    output
  end
end

Treetop::Runtime::SyntaxNode.send(:include, HTMLSyntax)

class LinebreakNode < Treetop::Runtime::SyntaxNode
  def to_html
    "<br/>\n"
  end
end

class LinkNode < Treetop::Runtime::SyntaxNode
  def to_html
    return '<a href="' + href.to_html + '">' + (desc.to_html.empty? ? href : desc).to_html + '</a>'
  end
end

