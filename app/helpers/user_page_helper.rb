# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
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

module UserPageHelper

  def userpage_contents(name, revision=nil)
    Raki.provider(:user_page).userpage_contents(name, revision)
  end

  def insert_userpage(name, revision=nil)
    if page_exists?(name, revision)
      parsed = Raki.parser(:user_page).parse(userpage_contents(name, revision))
      (parsed.nil?)?"<div class=\"error\">PARSING ERROR</div>":parsed
    end
  end

  def userpage_exists?(name, revision=nil)
    Raki.provider(:user_page).userpage_exists?(name, revision)
  end

  def userpage_revisions(name)
    Raki.provider(:user_page).userpage_revisions(name)
  end

end
