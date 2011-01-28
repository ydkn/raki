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

class RakiSyntax::RootNode < RakiSyntax::Node
  
  def self.enable_raki_syntax_on_node node
    node.extend RakiSyntax unless node.respond_to?(:to_html)
    
    node.elements.each do |e|
      enable_raki_syntax_on_node e
    end if node.elements
  end
  
  def enable_raki_syntax
    unless parent || @enabled_syntax_on_nodes
      self.class.enable_raki_syntax_on_node self
      @enabled_syntax_on_nodes = true
    end
  end
  
end
