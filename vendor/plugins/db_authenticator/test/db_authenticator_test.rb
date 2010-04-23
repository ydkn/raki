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

require 'test_helper'

class DBAuthenticatorTest < Test::Unit::TestCase

  def setup
    @authenticator = DBAuthenticator.new
  end

  # Try to authenticate user
  def test_auth
    user = User.new
    user.username = 'user1'
    user.email = 'user1@dom.org'
    user.password = 'passwd'
    user.save
    assert @authenticator.login('user1', 'passwd')
    user.destroy
  end

end
