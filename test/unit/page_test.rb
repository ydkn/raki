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

require 'test_helper'

class PageTest < Test::Unit::TestCase
  
  def test_find
    user = default_user
    Raki::Provider[:default].page_save('PageTest', 'FindMe', 'foo bar', 'message', user)
    page = Page.find 'PageTest', 'FindMe'
    assert_not_nil page
    assert_equal 'foo bar', page.content
    assert_equal page.revisions.first, page.revisions.last
    assert_equal 'message', page.revisions.last.message
    assert_equal user.username, page.revisions.last.user.username
  end
  
  private
  
  # Creates a user
  def user(username, email)
    User.new(Time.new.to_s, :username => username, :email => email)
  end
  
  # Default user
  def default_user
    @default_user ||= user('raki_parser_test', 'test@user.org')
  end
  
end
