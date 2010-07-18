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
    rnd = rand(900)+100
    
    types = params[:type].nil? ? [context[:type]] : params[:type].split(',')
    
    header = ""
    content = ""
    
    letters_pages(types).each do |letter, pages|
      
      header += "<a href=\"#INDEX-#{h letter}-#{rnd}\">#{h letter}</a> - "
      content += "<div class=\"index_letter\" id=\"INDEX-#{h letter}-#{rnd}\">#{h letter}</div><div class=\"index_pages\">"
      pages.each do |page|
        content += "<a href=\"#{url_for :controller => 'page', :action => 'view', :type => h(page[:type]), :id => h(page[:page])}\">#{h types.length == 1 ? page[:page] : "#{page[:type]}/#{page[:page]}"}</a>, "
      end
      content = content[0..-3]
      content += "</div>"
      
    end
    
    "<div class=\"index\"><div class=\"index_header\">#{header[0..-4]}</div><div class=\"index_body\">#{content}</div></div>"
  end

end
