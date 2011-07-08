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

module RakiSyntax
  
  include ERB::Util
  
  def to_html context
    return h text_value unless elements
    
    output = ''
    elements.each do |e|
      output += e.to_html context
    end
    output
  end
  
  def to_src context
    return text_value unless elements
    
    output = ''
    elements.each do |e|
      output += e.to_src context
    end
    output
  end
  
  def link_update from, to, context
    return false unless elements
    
    changed = false
    elements.each do |e|
      changed |= e.link_update from, to, context
    end
    changed
  end
  
  def sections context, sections=[]
    return sections unless elements
    
    elements.each do |e|
      e.sections context, sections
    end
    
    sections
  end
  
end

require 'raki_syntax/node'
require 'raki_syntax/root_node'
require 'raki_syntax/format_node'
require 'raki_syntax/heading_node'
require 'raki_syntax/hline_node'
require 'raki_syntax/link_node'
require 'raki_syntax/list_node'
require 'raki_syntax/message_box_node'
require 'raki_syntax/plugin_node'
require 'raki_syntax/table_node'
require 'raki_syntax/wiki_link_node'
