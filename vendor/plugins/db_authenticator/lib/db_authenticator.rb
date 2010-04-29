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

class DBAuthenticator < Raki::AbstractAuthenticator

  def login(username, password)
    begin
      user = User.find(username)
      return false if user.nil?
      (user.password == password)
    rescue
      false
    end
  end

  def form_fields
    [
      {
        :name => 'openid',
        :type => 'text',
        :title => 'auth.username'
      },
      {
        :name => 'password',
        :type => 'password',
        :title => 'auth.password'
      }
    ]
  end

end