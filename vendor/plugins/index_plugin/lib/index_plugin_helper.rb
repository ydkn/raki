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

module IndexPluginHelper
  
  def letters_pages type
    chars = {}
    Raki.provider(type).page_all(type).each do |page|
      letter = page[0].chr.upcase
      chars[letter] = [] unless chars.key?(letter)
      chars[letter] << page
    end
    chars.sort { |a,b| a <=> b }
  end
  
end
