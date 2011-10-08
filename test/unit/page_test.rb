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
  
  # Test page locking
  def test_locking
    Lock.all.each{|l| l.destroy}
    
    user = User.new 'raki_page_test', :username => 'raki_page_test', :email => 'test@user.org'
    user2 = User.new 'raki_page_test2', :username => 'raki_page_test2', :email => 'test2@user.org'
    page = Page.new(:namespace => 'PageLockTest', :name => 'PageName')
    
    # Lock and unlock
    assert !page.locked?
    assert_nil page.locked_by
    page.lock user
    assert page.locked?
    assert_equal user, page.locked_by
    page.unlock user
    assert !page.locked?
    assert_nil page.locked_by
    
    # Unlock with other user
    page.lock user
    page.unlock user2
    assert page.locked?
    assert_equal user, page.locked_by
    page.unlock user
    assert !page.locked?
    assert_nil page.locked_by
    
    # Lock with other user
    page.lock user
    assert page.locked?
    assert_equal user, page.locked_by
    page.lock user2
    assert page.locked?
    assert_equal user, page.locked_by
  end
  
  # Test locking and unlocking of multiple pages
  def test_locking_multiple
    Lock.all.each{|l| l.destroy}
    
    pages = ['Page1', 'Page2', 'Page3', 'Page4'].collect{|p| Page.new(:namespace => 'PageLockTest', :name => p)}
    users = {}
    pages.each{|p| users[p] = User.new(p.name, :username => p.name, :email => "#{p.name}@user.org")}
    
    pages.each do |page|
      assert !page.locked?
      assert_nil page.locked_by
    end
    
    pages.each do |page|
      assert !page.locked?
      page.lock users[page]
      assert page.locked?
      assert_equal users[page],  page.locked_by
    end
    
    pages.each do |page|
      assert page.locked?
      assert_equal users[page], page.locked_by
    end
    
    pages.each do |page|
      assert page.locked?
      assert_equal users[page], page.locked_by
      page.unlock users[page]
      assert !page.locked?
      assert_nil page.locked_by
    end
    
    pages.each do |page|
      assert !page.locked?
      assert_nil page.locked_by
    end
  end
  
end
