# Raki - extensible rails-based wiki
# Copyright (C) 2010 Martin Sigloch
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

class ImagePluginHelper
  class << self
    
    include Raki::Helpers

    def show(params, body, context)
      
      img = body.strip
      type = params[:type].nil? ? context[:type].to_s : params[:type]
      page = params[:page].nil? ? context[:page].to_s : params[:page]

      if isurl? img
        url = img
      else
        url = "/#{h type}/#{h page}/attachment/#{h img}"
      end

      width  = params[:width ].nil? ? ""  : "width=\"#{h params[:width]}\""
      height = params[:height].nil? ? ""  : "height=\"#{h params[:height]}\""
      alt    = params[:alt   ].nil? ? img : h(params[:alt])

      "<img src=\"#{url}\" alt=\"#{alt}\" #{width} #{height} />"
    end

    def isurl? string
      string.include? "://"
    end

  end
end
