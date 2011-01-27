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
  
  def raki_syntax_html context
    return text_value unless elements
    
    output = ''
    elements.each do |e|
      output += e.raki_syntax_html context
    end
    output
  end
  
  def raki_syntax_src context
    return text_value unless elements
    
    output = ''
    elements.each do |e|
      output += e.raki_syntax_src context
    end
    output
  end
  
  def raki_syntax_link_update from, to, context
    return false unless elements
    
    changed = false
    elements.each do |e|
      changed |= e.raki_syntax_link_update from, to, context
    end
    changed
  end
  
  def raki_syntax_sections context, sections=[]
    return sections unless elements
    
    elements.each do |e|
      e.raki_syntax_sections context, sections
    end
    
    sections
  end
  
end
