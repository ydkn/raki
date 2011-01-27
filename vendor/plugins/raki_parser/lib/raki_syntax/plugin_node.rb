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

class RakiSyntax::PluginNode < RakiSyntax::Node

  def raki_syntax_html context
    if defined?(body) && body
      text = body.text_value
    else
      text = ''
    end
    
    params = {}
    if defined?(param)
      param.elements.each do |element|
        params.merge! element.parameter.keyval
      end
    end
    
    Raki::Plugin.execute(name.text_value, params, text, context).to_s
    
  rescue Raki::Plugin::PluginError => e
    "<div class=\"error\"><b>#{h e.to_s}</b></div>"
  rescue => e
    Rails.logger.error "Plugin '#{name.text_value}' caused error (#{e.class}): #{e.to_s}\n#{e.backtrace.join "\n"}"
    "<div class=\"error\"><b>#{t 'plugin.error', :name => name.text_value}</b></div>"
  end

end


class RakiSyntax::ParameterNode < RakiSyntax::Node

  def keyval
    Hash[key.text_value.to_sym, value.text.text_value]
  end

end
