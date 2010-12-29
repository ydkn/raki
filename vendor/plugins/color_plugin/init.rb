# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab & Martin Sigloch
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

Raki::Plugin.register /^red|blue|green|yellow|grey|black|white|[0-9a-f]{3}|[0-9a-f]{6}$/i do
  
  name 'Color Plugin'
  description 'Changes the text color'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'
  
  execute do
    colors = {
        :red => 'f00',
        :green => '0f0',
        :blue => '00f',
        :yellow => 'ff0',
        :grey => 'aaa',
        :black => '000',
        :white => 'fff'
      }
    
    if callname.to_s =~ /^[0-9a-f]{3}|[0-9a-f]{6}$/i
      render :inline => "<font style=\"color:##{callname.to_s};\">#{parse context[:page].namespace, body}</font>"
    elsif colors.key? callname.to_sym
      render :inline => "<font style=\"color:##{colors[callname.to_sym]};\">#{parse context[:page].namespace, body}</font>"
    else
      raise t('color.invalid_color')
    end
  end
  
end
