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

Raki::Plugin.register :referring_pages do

  name 'ReferringPages plugin'
  description 'Plugin to show a list of all referring pages'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'

  execute do
    if params[:page]
      page = page_for params[:page]
    else
      page = context[:real_page] || context[:page]
    end
    
    @referring_pages = page.referring_pages :only_head => true
  end

end
