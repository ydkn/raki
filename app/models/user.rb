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
  
  include Raki::Helpers::URLHelper
  
  attr_reader :id
  
  def initialize(id, options={})
    @id = id
    @username = options[:username] ? options[:username].gsub(/[^a-z0-9_\- ]/i, '') : nil
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
  
  def authorized_to?(page, action='view')
    page.authorized?(self, action)
  end
  
  def page
    @page ||= Page.new(:namespace => Raki.userpage_namespace, :name => username)
  end
  
  def == b
    b.is_a?(User) && (id == b.id || username == b.username)
  end
  
  def to_hash
    {:id => id, :username => username, :email => email, :display_name => display_name}
  end
  alias :to_h :to_hash
  
  def self.current
    @current
  end

  def self.current=(user)
    if user.is_a?(Hash) && user[:id]
      @current = User.new(user[:id], user)
    elsif user.is_a?(User)
      @current = user
    else
      @current = nil
    end
  end
  
end
