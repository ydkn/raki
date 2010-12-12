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

Raki::Plugin.register :index do

  name 'Index plugin'
  description 'Plugin to list all wiki pages'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'

  add_stylesheet '/plugin_assets/index_plugin/stylesheets/index.css'

  include IndexPluginHelper

  execute do
    p_namespaces = params[:namespace].nil? ? [context[:namespace]] : params[:namespace].split(',')
    p_namespaces = namespaces if params[:namespace] == 'all'
    
    chars = {}
    
    p_namespaces.each do |namespace|
      namespace = namespace.to_sym
      
      page_all!(namespace).each do |page|
        letter = page[0].chr.upcase
        chars[letter] = [] unless chars.key?(letter)
        chars[letter] << {:namespace => namespace, :page => page}
      end
      
    end
    
    @index = []
    keys = chars.keys.sort {|a,b| a <=> b}
    keys.each do |key|
      @index << {
          :letter => key,
          :pages => sort_pages(chars[key])
        }
    end
    @rnd = rand(900)+100
    
    render :inline => "<b>#{t 'indexplugin.no_pages'}</b>" if @index.empty?
  end

end
