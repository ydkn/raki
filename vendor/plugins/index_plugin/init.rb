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

  execute do
    if context[:live_preview]
      render :inline => "<div class=\"warning\">#{t('plugin.not_available_in_live_preview')}</div>"
    else
      @namespaces = params[:namespace].nil? ? [context[:page].namespace] : params[:namespace].split(',')
      @namespaces = nil if params[:namespace] == 'all'

      chars = {}

      Page.all(:namespace => @namespaces).select{|p| p.authorized?(User.current, :view)}.each do |page|
        letter = page.name[0].chr.upcase
        chars[letter] = [] unless chars.key?(letter)
        chars[letter] << page
      end

      @index = []
      keys = chars.keys.sort {|a,b| a <=> b}
      keys.each do |key|
        @index << {
            :letter => key,
            :pages => chars[key].sort
          }
      end
      @rnd = rand(900)+100

      render :inline => "<b>#{t 'indexplugin.no_pages'}</b>" if @index.empty?
    end
  end

end
