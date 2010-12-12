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

Raki::Plugin.register :img do

  name 'Image plugin'
  description 'Plugin to display images'
  url 'http://github.com/ydkn/raki'
  author 'Martin Sigloch'
  version '0.1'

  execute do
    img = body.strip
    namespace = params[:namespace].nil? ? context[:namespace].to_s : params[:namespace]
    page = params[:page].nil? ? context[:page].to_s : params[:page]
    
    url = url?(img) ? img : "/#{namespace}/#{page}/attachment/#{img}"
    
    alt = params[:alt].nil? ? img : params[:alt]
    
    attributes = []
    attributes << "width=\"#{h params[:width]}\"" unless params[:width].nil?
    attributes << "height=\"#{h params[:height]}\"" unless params[:height].nil?
    
    render :inline => "<img src=\"#{h url}\" alt=\"#{h alt}\" #{attributes.join ' '} />"
  end

end
