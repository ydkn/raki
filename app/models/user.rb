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

class User
  
  include Raki::Helpers::AuthorizationHelper
  include Raki::Helpers::URLHelper
  
  attr_reader :id
  
  def initialize(id, options={})
    @id = id
    @username = options[:username]
    @email = options[:email]
    @display_name = options[:display_name]
  end
  
  def username
    @username || @id
  end
  
  def email
    @email || "#{username}@#{Raki.app_name.underscore}"
  end
  
  def display_name
    @display_name || username
  end
  
  def authorized_to?(namespace, page, action)
    authorized?(namespace, page, action, self)
  end
  
  def authorized_to!(namespace, page, action)
    authorized!(namespace, page, action, self)
  end
  
  def page_url
    url_for_page(Raki.userpage_namespace, username)
  end
  
  def == b
    id == b.id
  end
  
  def self.current
    @current
  end

  def self.current=(user)
    @current = user
  end
  
end
