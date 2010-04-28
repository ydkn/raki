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

class GitProviderTest < Test::Unit::TestCase

  # Setup a GIT repository for testing
  def setup
    FileUtils.remove_dir("#{Rails.root}/tmp/test-git-repo", true) if File.exists?("#{Rails.root}/tmp/test-git-repo")
    `git init #{Rails.root}/tmp/test-git-repo`
    Dir.mkdir("#{Rails.root}/tmp/test-git-repo/pages")
    File.new("#{Rails.root}/tmp/test-git-repo/pages/.keep", 'w').close
    Dir.mkdir("#{Rails.root}/tmp/test-git-repo/users")
    File.new("#{Rails.root}/tmp/test-git-repo/users/.keep", 'w').close
    `cd #{Rails.root}/tmp/test-git-repo && git add . && git commit -m \"created folders\" --author=\"unittest <test@unit.rake>\"`
    @provider = GitProvider.new({'path' => "#{Rails.root}/tmp/test-git-repo"})
  end

  # Remove GIT repository after testing
  def teardown
    FileUtils.remove_dir("#{Rails.root}/tmp/test-git-repo", true)
  end

  # Try to access an invalid repository
  def test_invalid_repository
    teardown
    assert_raise(Raki::AbstractProvider::ProviderError) do
      page_exists?('SomePage')
    end
    assert_raise(Raki::AbstractProvider::ProviderError) do
      page_contents('SomePage')
    end
    assert_raise(Raki::AbstractProvider::ProviderError) do
      page_revisions('SomePage')
    end
    assert_raise(Raki::AbstractProvider::ProviderError) do
      page_save('SomePage', 'some content', 'test', default_user)
    end
  end

  # Create a new page and test if it exists
  def test_page_exists
    page_name = 'PageExsist'
    assert !page_exists?(page_name)
    page_save page_name, "some content", 'changed', default_user
    assert page_exists?(page_name)
  end

  # Create a new page
  def test_create_page
    page_names = ['TestPage','Page with spaces']
    page_names.each do |page_name|
      content = "test content 123"
      page_save page_name, content, 'changed', default_user
      assert page_exists?(page_name)
      assert_equal content, page_contents(page_name)
      revisions = page_revisions page_name
      assert_equal 1, revisions.length
      assert_equal default_user.username, revisions[0].user
    end
  end

  # Update page contents
  def test_update_page
    page_name = 'TestPage2'
    old_content = "content"
    page_save page_name, old_content, 'create', default_user
    assert_equal old_content, page_contents(page_name)
    new_content = "new content"
    update_user = user 'updater', 'updater@dom.org'
    page_save page_name, new_content, 'update', update_user
    assert_equal new_content, page_contents(page_name)
    revisions = page_revisions page_name
    assert_equal 2, revisions.length
    assert_equal default_user.username, revisions[0].user
    assert_equal update_user.username, revisions[1].user
  end

  # Rename page
  def test_rename_page
    old_page = 'TestPage'
    new_page = 'TestPageRenamed'
    page_save old_page, "some content", 'create', default_user
    content = page_contents old_page
    rename_user = user 'renamer', 'renamer@dom.org'
    page_rename old_page, new_page, rename_user
    assert !page_exists?(old_page)
    assert page_exists?(new_page)
    assert_equal content, page_contents(new_page)
    revisions = page_revisions new_page
    assert_equal 1, revisions.length
    assert_equal rename_user.username, revisions[0].user
  end

  # Delete a existing page
  def test_delete_page
    page_name = 'TestPageToDelete'
    page_save page_name, "some content", 'create', default_user
    delete_user = user 'deleter', 'deleter@dom.org'
    page_delete page_name, delete_user
    assert !page_exists?(page_name)
  end

  # Check for index of all pages
  def test_page_index
    page_names = ['TestPage','TestPage2',"TestPage3","TestPage"]
    page_names.each do |page_name|
      page_save page_name, "Content for page: #{page_name}", 'create', default_user
    end
    page_all.each do |page|
      assert page_names.include?(page) if page != '.keep'
    end
  end

  # Update page and check revisions
  def test_page_revisions
    page_name = 'TestPageRev'
    user1 = user 'user1', 'u1@dom.org'
    user2 = user 'user2', 'u2@dom.org'
    user3 = user 'user3', 'u3@dom.org'
    page_save page_name, "test content", 'create', user1
    revisions = page_revisions page_name
    assert_equal 1, revisions.length
    assert_equal user1.username, revisions[0].user
    assert_equal 'create', revisions[0].message
    page_save page_name, "updated content", 'update', user2
    revisions = page_revisions page_name
    assert_equal 2, revisions.length
    assert_equal user2.username, revisions[1].user
    assert_equal user1.username, revisions[0].user
    assert_not_equal revisions[0].version, revisions[1].version
    assert_equal 'update', revisions[1].message
    assert_equal 'create', revisions[0].message
    page_save page_name, "new updated content", 'update2', user3
    revisions = page_revisions page_name
    assert_equal 3, revisions.length
    assert_equal user3.username, revisions[2].user
    assert_equal user1.username, revisions[0].user
    assert_not_equal revisions[0].version, revisions[2].version
    assert_not_equal revisions[1].version, revisions[2].version
    assert_not_equal revisions[0].version, revisions[1].version
    assert_equal 'update2', revisions[2].message
    assert_equal 'update', revisions[1].message
  end

  # Create a new userpage and test if it exists
  def test_userpage_exists
    user = 'SomeUser'
    assert !userpage_exists?(user)
    userpage_save user, "some content", 'changed', default_user
    assert userpage_exists?(user)
  end

  # Update userpage contents
  def test_edit_userpage
    user = 'SomeUser'
    old_content = "content"
    userpage_save user, old_content, 'create', default_user
    assert_equal old_content, userpage_contents(user)
    new_content = "new content"
    update_user = user 'updater', 'updater@dom.org'
    userpage_save user, new_content, 'update', update_user
    assert_equal new_content, userpage_contents(user)
    revisions = userpage_revisions user
    assert_equal 2, revisions.length
    assert_equal default_user.username, revisions[0].user
    assert_equal update_user.username, revisions[1].user
  end

  # Delete a existing userpage
  def test_delete_userpage
    user = 'SomeUserToDelete'
    userpage_save user, "some content", 'create', default_user
    delete_user = user 'deleter', 'deleter@dom.org'
    userpage_delete user, delete_user
    assert !userpage_exists?(user)
  end

  # Check for index of all userpages
  def test_userpage_index
    user_names = ['User1','User2',"User3","User4"]
    user_names.each do |user_name|
      userpage_save user_name, "Content for user: #{user_name}", 'create', default_user
    end
    userpage_all.each do |user|
      assert user_names.include?(user) if user != '.keep'
    end
  end

  private

  # Creates a user
  def user(username, email)
    u = User.new
    u.username = username
    u.email = email
    u
  end

  # Default user
  def default_user
    @default_user = user('testuser', 'test@user.org') if @default_user.nil?
    @default_user
  end

  def page_exists?(name)
    @provider.page_exists? name
  end

  def page_contents(name)
    @provider.page_contents name
  end

  def page_revisions(name)
    @provider.page_revisions name
  end

  def page_save(name, content, message, user)
    @provider.page_save name, content, message, user
  end

  def page_rename(old_name, new_name, user)
    @provider.page_rename old_name, new_name, user
  end

  def page_delete(name, user)
    @provider.page_delete name, user
  end

  def page_all
    @provider.page_all
  end

  def userpage_exists?(name)
    @provider.userpage_exists? name
  end

  def userpage_contents(user)
    @provider.userpage_contents user
  end

  def userpage_revisions(user)
    @provider.userpage_revisions user
  end

  def userpage_save(user, content, message, user_changing)
    @provider.userpage_save user, content, message, user_changing
  end

  def userpage_delete(user, user_changing)
    @provider.userpage_delete user, user_changing
  end

  def userpage_all
    @provider.page_all
  end

end
