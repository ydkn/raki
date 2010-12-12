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

Raki::Plugin.register :example do

  name 'Example plugin'
  description 'Example plugin to demonstrate plugin system'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'

  execute do
    if params.key?(:error)
      raise "ERROR: #{params[:error]}"
    end
    
    context_out = context.inspect.gsub /\\/, ''
    params_out = params.inspect.gsub /\\/, ''
    body_out = body.inspect.gsub(/^"(.*)"$/, '\1').gsub /\\/, ''
    
    render :inline => "
      <div class=\"information\">
      <b>Example Plugin</b><br/><br/>
      Context: #{h context_out}<br/>
      Parameters: #{h params_out}<br/>
      Body: #{h body_out}
      </div>"
  end

end
