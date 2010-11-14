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

Raki::Plugin.register :youtube do

  name 'Youtube plugin'
  description 'Plugin embed Youtube videos into wiki pages'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'

  execute do
    url = body.strip
    if params['http://www.youtube.com/watch?v'.to_sym]
      url = "http://www.youtube.com/watch?v=#{params['http://www.youtube.com/watch?v'.to_sym].strip}"
    end
    if url =~ /^http:\/\/www.youtube.com\/embed\/([^\?&]+)/i
      @video_id = $1
    elsif url =~ /^http:\/\/www.youtube.com\/watch\?v=([^\?&]+)/i
      @video_id = $1
    else
      @video_id = url
    end
    render :youtube_embedded
  end

end
