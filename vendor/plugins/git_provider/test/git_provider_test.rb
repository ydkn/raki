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
      page_exists?(:page, 'SomePage')
    end
    assert_raise(Raki::AbstractProvider::ProviderError) do
      page_contents(:page, 'SomePage')
    end
    assert_raise(Raki::AbstractProvider::ProviderError) do
      page_revisions(:page, 'SomePage')
    end
    assert_raise(Raki::AbstractProvider::ProviderError) do
      page_save(:page, 'SomePage', 'some content', 'test', default_user)
    end
  end

  # Create a new page and test if it exists
  def test_page_exists
    page_name = 'PageExsist'
    assert !page_exists?(:page, page_name)
    page_save :page, page_name, "some content", 'changed', default_user
    assert page_exists?(:page, page_name)
  end

  # Create a new page
  def test_create_page
    page_names = ['TestPage','Page with spaces']
    page_names.each do |page_name|
      content = "test content 123"
      page_save :page, page_name, content, 'changed', default_user
      assert page_exists?(:page, page_name)
      assert_equal content, page_contents(:page, page_name)
      revisions = page_revisions :page, page_name
      assert_equal 1, revisions.length
      assert_equal default_user.username, revisions[0].user
    end
  end

  # Update page contents
  def test_update_page
    page_name = 'TestPage2'
    old_content = "content"
    page_save :page, page_name, old_content, 'create', default_user
    assert_equal old_content, page_contents(:page, page_name)
    new_content = "new content"
    update_user = user 'updater', 'updater@dom.org'
    page_save :page, page_name, new_content, 'update', update_user
    assert_equal new_content, page_contents(:page, page_name)
    revisions = page_revisions :page, page_name
    assert_equal 2, revisions.length
    assert_equal default_user.username, revisions[0].user
    assert_equal update_user.username, revisions[1].user
  end

  # Rename page
  def test_rename_page
    old_page = 'TestPage'
    new_page = 'TestPageRenamed'
    page_save :page, old_page, "some content", 'create', default_user
    content = page_contents :page, old_page
    rename_user = user 'renamer', 'renamer@dom.org'
    page_rename :page, old_page, new_page, rename_user
    assert !page_exists?(:page, old_page)
    assert page_exists?(:page, new_page)
    assert_equal content, page_contents(:page, new_page)
    revisions = page_revisions :page, new_page
    assert_equal 1, revisions.length
    assert_equal rename_user.username, revisions[0].user
  end

  # Delete a existing page
  def test_delete_page
    page_name = 'TestPageToDelete'
    page_save :page, page_name, "some content", 'create', default_user
    delete_user = user 'deleter', 'deleter@dom.org'
    page_delete :page, page_name, delete_user
    assert !page_exists?(:page, page_name)
  end

  # Check for index of all pages
  def test_page_index
    page_names = ['TestPage','TestPage2',"TestPage3","TestPage"]
    page_names.each do |page_name|
      page_save :page, page_name, "Content for page: #{page_name}", 'create', default_user
    end
  end

  # Update page and check revisions
  def test_page_revisions
    page_name = 'TestPageRev'
    user1 = user 'user1', 'u1@dom.org'
    user2 = user 'user2', 'u2@dom.org'
    user3 = user 'user3', 'u3@dom.org'
    page_save :page, page_name, "test content", 'create', user1
    revisions = page_revisions :page, page_name
    assert_equal 1, revisions.length
    assert_equal user1.username, revisions[0].user
    assert_equal 'create', revisions[0].message
    page_save :page, page_name, "updated content", 'update', user2
    revisions = page_revisions :page, page_name
    assert_equal 2, revisions.length
    assert_equal user2.username, revisions[1].user
    assert_equal user1.username, revisions[0].user
    assert_not_equal revisions[0].version, revisions[1].version
    assert_equal 'update', revisions[1].message
    assert_equal 'create', revisions[0].message
    page_save :page, page_name, "new updated content", 'update2', user3
    revisions = page_revisions :page, page_name
    assert_equal 3, revisions.length
    assert_equal user3.username, revisions[2].user
    assert_equal user1.username, revisions[0].user
    assert_not_equal revisions[0].version, revisions[2].version
    assert_not_equal revisions[1].version, revisions[2].version
    assert_not_equal revisions[0].version, revisions[1].version
    assert_equal 'update2', revisions[2].message
    assert_equal 'update', revisions[1].message
  end

  def test_attachment_exists
    page = 'TestPage'
    attachment = 'SomeFile.test'
    data = generate_binary_data
    assert !attachment_exists?(:page, page, attachment)
    attachment_save(:page, page, attachment, data, "test message", default_user)
    assert attachment_exists?(:page, page, attachment)
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

  def page_exists?(type, name)
    @provider.page_exists? type, name
  end

  def page_contents(type, name)
    @provider.page_contents type, name
  end

  def page_revisions(type, name)
    @provider.page_revisions type, name
  end

  def page_save(type, name, content, message, user)
    @provider.page_save type, name, content, message, user
  end

  def page_rename(type, old_name, new_name, user)
    @provider.page_rename type, old_name, new_name, user
  end

  def page_delete(type, name, user)
    @provider.page_delete type, name, user
  end

  def page_all(type=nil)
    @provider.page_all type
  end

  def attachment_exists?(type, page, name)
    @provider.attachment_exists? type, page, name
  end

  def attachment_save(type, page, name, contents, message, user)
    @provider.attachment_save type, page, name, contents, message, user
  end

  def generate_binary_data(length=nil)
    length = 1024 + rand(4096) if length.nil?
    data = ""
    file = File.new("/dev/random", "r")
    length.times do
      data += file.gets
    end
    file.close
    data
  end

end
