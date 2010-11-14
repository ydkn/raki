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

Raki::Plugin.register :recentchanges do

  name 'Recent changes plugin'
  description 'Plugin to list recent changes'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'

  add_stylesheet '/plugin_assets/recentchanges_plugin/stylesheets/recentchanges.css'
  
  include RecentchangesPluginHelper

  execute do
    @namespaces = params[:namespace].nil? ? [context[:namespace]] : params[:namespace].split(',')
    @namespaces = namespaces if params[:namespace] == 'all'
    
    @options = {}
    @options[:limit] = params[:limit].to_i if params[:limit]
    @options[:since] = params[:since].to_i.days.ago if params[:since]
    
    render :recentchanges
  end

end
