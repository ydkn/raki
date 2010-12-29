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
  
  # Test find
  def test_find
    user = User.new Time.new.to_s, :username => 'raki_page_test', :email => 'test@user.org'
    
    # Existing page without revision and with valid revision
    Raki::Provider[:default].page_save 'PageTest', 'FindMe', 'foo bar', 'message', user
    rev1 = Raki::Provider[:default].page_revisions('PageTest', 'FindMe').first
    
    [Page.find('PageTest', 'FindMe'), Page.find('PageTest', 'FindMe', rev1[:id])].each do |page|
      assert_not_nil page
      assert_equal 'foo bar', page.content
      assert_equal rev1[:id], page.revisions.first.id
      assert_equal page.revisions.first, page.revisions.last
      assert_equal 'message', page.revisions.last.message
      assert_equal user.username, page.revisions.last.user.username
    end
    
    # Existing page with older revision
    Raki::Provider[:default].page_save 'PageTest', 'FindMe', 'bar foo', 'message2', user
    rev2 = Raki::Provider[:default].page_revisions('PageTest', 'FindMe').first
    
    page = Page.find 'PageTest', 'FindMe', rev1[:id]
    
    assert_not_nil page
    assert_equal 'foo bar', page.content
    assert_equal rev2[:id], page.revisions.first.id
    assert_equal rev1[:id], page.revisions.last.id
    assert_equal 'message2', page.revisions.first.message
    assert_equal 'message', page.revisions.last.message
    assert_equal user.username, page.revisions.first.user.username
    
    # Existing page with invalid revision
    page = Page.find 'PageTest', 'FindMe', 'InvalidRevision'
    assert_nil page
  end
  
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
