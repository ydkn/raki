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

class RakiSyntax::FormatNode < RakiSyntax::Node
  
  def self.pre pre=nil
    @pre = pre if pre
    @pre
  end
  
  def self.post post=nil
    @post = post if post
    @post
  end

  def to_html context
    "#{self.class.pre}#{text.to_html(context)}#{self.class.post}"
  end
  
end


class RakiSyntax::BoldNode < RakiSyntax::FormatNode
  
  pre '<b>'
  post '</b>'
  
end


class RakiSyntax::ItalicNode < RakiSyntax::FormatNode
  
  pre '<i>'
  post '</i>'
  
end


class RakiSyntax::UnderlineNode < RakiSyntax::FormatNode

  pre '<span class="underline">'
  post '</span>'
  
end


class RakiSyntax::StrikethroughNode < RakiSyntax::FormatNode
  
  pre '<del>'
  post '</del>'

end
