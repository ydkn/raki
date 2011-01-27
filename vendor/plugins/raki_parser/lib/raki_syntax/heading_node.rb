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

class RakiSyntax::HeadingNode < RakiSyntax::Node

  def raki_syntax_html context
    "<h#{level_num} id=\"#{anchor}\">#{text.raki_syntax_html(context).strip}</h#{level_num}>"
  end
  
  def raki_syntax_sections context, sections=[]
    s = sections
    (level_num-1).times do |i|
      s << {:subsections => []} unless s.last
      s.last[:subsections] = [] unless s.last[:subsections]
      s = s.last[:subsections]
    end
    
    s << {:anchor => anchor, :title => text.raki_syntax_html(context).strip, :subsections => []}
    
    sections
  end
  
  private
  
  def real_level_num
    level.text_value.length.to_i
  end
  
  def level_num
    real_level_num > 6 ? 6 : real_level_num
  end
  
  def anchor
    h "section-#{text.text_value.gsub(/[^a-zA-Z0-9 _-]/, '').strip.gsub(/\s+/, '_')}"
  end

end
