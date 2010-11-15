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

class LockManagerTest < Test::Unit::TestCase
  
  # Test if page is locked
  def test_lock_page
    page = Page.new(:namespace => 'ns', :name => 'PageName')
    
    # Lock and unlock
    assert !Raki::LockManager.locked?(page)
    Raki::LockManager.lock(page, default_user)
    assert Raki::LockManager.locked?(page)
    Raki::LockManager.unlock(page, default_user)
    assert !Raki::LockManager.locked?(page)
    
    # Unlock with other user
    Raki::LockManager.lock(page, default_user)
    Raki::LockManager.unlock(page, user('testuser2', 'test2@user.org'))
    assert Raki::LockManager.locked?(page)
  end
  
  # Test locking and unlocking of multiple pages
  def test_lock_multiple
    page_names = ['Page1', 'Page2', 'Page3', 'Page4']
    pages = page_names.map{|p| Page.new(:namespace => 'ns', :name => p)}
    users = {}
    pages.each{|p| users[p] = user(p.name, "#{p.name}@user.org")}
    
    pages.each do |page|
      assert !Raki::LockManager.locked?(page)
      assert_nil Raki::LockManager.locked_by(page)
    end
    
    pages.each do |page|
      assert !Raki::LockManager.locked?(page)
      Raki::LockManager.lock(page, users[page])
      assert Raki::LockManager.locked?(page)
      assert_equal users[page], Raki::LockManager.locked_by(page)
    end
    
    pages.each do |page|
      assert Raki::LockManager.locked?(page)
      assert_equal users[page], Raki::LockManager.locked_by(page)
    end
    
    pages.each do |page|
      assert Raki::LockManager.locked?(page)
      assert_equal users[page], Raki::LockManager.locked_by(page)
      Raki::LockManager.unlock(page, users[page])
      assert !Raki::LockManager.locked?(page)
      assert_nil Raki::LockManager.locked_by(page)
    end
    
    pages.each do |page|
      assert !Raki::LockManager.locked?(page)
      assert_nil Raki::LockManager.locked_by(page)
    end
  end
  
  # Test if page is locked by user
  def test_locked_by
    page = Page.new(:namespace => 'ns', :name => 'LockedByPageName')
    user1 = user('user1', 'user1@test.org')
    user2 = user('user2', 'user2@test.org')
    
    assert_nil Raki::LockManager.locked_by(page)
    Raki::LockManager.lock(page, user1)
    assert_equal user1, Raki::LockManager.locked_by(page)
    Raki::LockManager.unlock(page, user1)
    assert_nil Raki::LockManager.locked_by(page)
    
    # Lock with other user
    Raki::LockManager.lock(page, user1)
    assert_equal user1, Raki::LockManager.locked_by(page)
    Raki::LockManager.lock(page, user2)
    assert_equal user1, Raki::LockManager.locked_by(page)
    
    # Unlock with other user
    Raki::LockManager.lock(page, user1)
    Raki::LockManager.unlock(page, user2)
    assert_equal user1, Raki::LockManager.locked_by(page)
    Raki::LockManager.unlock(page, user1)
    assert_nil Raki::LockManager.locked_by(page)
  end
  
  private
  
  # Creates a user
  def user(username, email)
    User.new(username, :username => username, :email => email)
  end

  # Default user
  def default_user
    @default_user = user('testuser', 'test@user.org') if @default_user.nil?
    @default_user
  end
  
end
