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
    @provider = GitProvider.new({'path' => "#{Rails.root}/tmp/test-git-repo"})
  end

  # Remove GIT repository after testing
  def teardown
    FileUtils.remove_dir("#{Rails.root}/tmp/test-git-repo", true)
  end

  # Create a new page
  def test_create_page
    page_name = 'TestPage'
    content = "test content 123"
    page_save page_name, content, 'changed', default_user
    assert page_exists?(page_name)
    assert_equal content, page_contents(page_name)
    revisions = page_revisions page_name
    assert_equal 1, revisions.length
    assert_equal default_user.username, revisions[0].user
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

end
