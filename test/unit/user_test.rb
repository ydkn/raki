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

class UserTest < Test::Unit::TestCase
  
  def test_attributes
    # Only id
    u = User.new 'user-id'
    assert_equal 'user-id', u.id
    assert_equal 'user-id', u.username
    assert_equal "user-id@#{Raki.app_name.underscore}", u.email
    assert_equal 'user-id', u.display_name
    
    # username
    u = User.new 'user-id', :username => 'testuser'
    assert_equal 'user-id', u.id
    assert_equal 'testuser', u.username
    assert_equal "testuser@#{Raki.app_name.underscore}", u.email
    assert_equal 'testuser', u.display_name
    
    # email
    u = User.new 'user-id', :email => 'testuser@test.dom'
    assert_equal 'user-id', u.id
    assert_equal 'user-id', u.username
    assert_equal 'testuser@test.dom', u.email
    assert_equal 'user-id', u.display_name
    
    # email
    u = User.new 'user-id', :display_name => 'John Doe'
    assert_equal 'user-id', u.id
    assert_equal 'user-id', u.username
    assert_equal "user-id@#{Raki.app_name.underscore}", u.email
    assert_equal 'John Doe', u.display_name
    
    # username and email
    u = User.new 'user-id', :username => 'testuser', :email => 'testuser@test.dom'
    assert_equal 'user-id', u.id
    assert_equal 'testuser', u.username
    assert_equal 'testuser@test.dom', u.email
    assert_equal 'testuser', u.display_name
    
    # username and display_name
    u = User.new 'user-id', :username => 'testuser', :display_name => 'John Doe'
    assert_equal 'user-id', u.id
    assert_equal 'testuser', u.username
    assert_equal "testuser@#{Raki.app_name.underscore}", u.email
    assert_equal 'John Doe', u.display_name
    
    # email and display_name
    u = User.new 'user-id', :email => 'testuser@test.dom', :display_name => 'John Doe'
    assert_equal 'user-id', u.id
    assert_equal 'user-id', u.username
    assert_equal 'testuser@test.dom', u.email
    assert_equal 'John Doe', u.display_name
  end
  
end
