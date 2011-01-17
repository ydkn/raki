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
require 'digest/md5'

class GitProviderTest < Test::Unit::TestCase

  # Setup a GIT repository for testing
  def setup
    @repo_path = File.join(Rails.root, 'tmp', 'test-git-repo')
    @tmp_repo_path = File.join(Rails.root, 'tmp', 'gitrepos', "#{Digest::MD5.hexdigest(@repo_path)}_test")
    
    `git init --bare #{@repo_path}`
    @provider = GitProvider.new('test', {'path' => @repo_path})
  end

  # Remove GIT repository after testing
  def teardown
    FileUtils.remove_dir(@repo_path, true) if @repo_path && File.exists?(@repo_path)
    FileUtils.remove_dir(@tmp_repo_path, true) if @tmp_repo_path && File.exists?(@tmp_repo_path)
  end

  # Try to create with an invalid repository
  def test_invalid_repository
    assert_raise(Raki::AbstractProvider::ProviderError) do
      GitProvider.new(:invalid, {'path' => File.join(Rails.root, 'tmp', 'test-git-repo-not-exists')})
    end
  end

  # Create a new page and test if it exists
  def test_page_exists
    page_name = 'PageExsist'
    assert !page_exists?(:page, page_name)
    page_save :page, page_name, "some content", 'changed', default_user
    assert page_exists?(:page, page_name)
  end
  
  # Test page content
  def test_page_content
    content = "some content"
    page_save :page, 'ContentTestPage', content, 'changed', default_user
    assert_equal content, page_contents(:page, 'ContentTestPage')
    
    assert_raise(Raki::AbstractProvider::PageNotExists) do
      page_contents :page, 'ContentTestPage2'
    end
    
    assert_raise(Raki::AbstractProvider::PageNotExists) do
      page_contents :page, 'ContentTestPage', 'InvalidRevision'
    end
  end

  # Create a new page
  def test_create_page
    namespace_names = [:page, :test]
    page_names = ['TestPage', 'Page with spaces', ',.-_#+*', '¥≈ç√∫~µ∞å∂ƒ©ª∆@æ«∑€®†Ω¨⁄øπ•±']
    namespace_names.each do |namespace_name|
      page_names.each do |page_name|
        content = "test content 123"
        page_save namespace_name, page_name, content, 'changed', default_user
        assert page_exists?(namespace_name, page_name)
        assert_equal content, page_contents(namespace_name, page_name)
        revisions = page_revisions namespace_name, page_name
        assert_equal 1, revisions.length
        assert_same_user default_user, revisions[0][:user]
      end
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
    assert_same_user default_user, revisions[1][:user]
    assert_same_user update_user, revisions[0][:user]
  end

  # Rename page
  def test_rename_page
    old_page = {:namespace => :page, :page => 'TestPage'}
    new_page = {:namespace => :page, :page => 'TestPageRenamed'}
    new_page2 = {:namespace => :test, :page => 'TestPageRenamedInOthernamespace'}
    
    # same namespace
    page_save old_page[:namespace], old_page[:page], "some content", 'create', default_user
    content = page_contents old_page[:namespace], old_page[:page]
    rename_user = user 'renamer', 'renamer@dom.org'
    page_rename old_page[:namespace], old_page[:page], new_page[:namespace], new_page[:page], rename_user
    assert !page_exists?(old_page[:namespace], old_page[:page])
    assert page_exists?(new_page[:namespace], new_page[:page])
    assert_equal content, page_contents(new_page[:namespace], new_page[:page])
    revisions = page_revisions new_page[:namespace], new_page[:page]
    assert_equal 1, revisions.length
    assert_same_user rename_user, revisions[0][:user]
    
    # other namespace
    rename_user2 = user 'renamer2', 'renamer2@other-dom.net'
    page_rename new_page[:namespace], new_page[:page], new_page2[:namespace], new_page2[:page], rename_user2
    assert !page_exists?(new_page[:namespace], new_page[:page])
    assert page_exists?(new_page2[:namespace], new_page2[:page])
    assert_equal content, page_contents(new_page2[:namespace], new_page2[:page])
    revisions = page_revisions new_page2[:namespace], new_page2[:page]
    assert_equal 1, revisions.length
    assert_same_user rename_user2, revisions[0][:user]
    
    # target page already exists
    page = {:namespace => :page, :page => 'TestPage2'}
    page2 = {:namespace => :test, :page => 'TestPage3'}
    page_save page[:namespace], page[:page], 'foo bar', 'create', default_user
    page_save page2[:namespace], page2[:page], 'bar foo', 'create2', default_user
    assert_raise(Raki::AbstractProvider::ProviderError) do
      page_rename page2[:namespace], page2[:page], page[:namespace], page[:page], rename_user
    end
  end

  # Delete a existing page
  def test_delete_page
    page_name = 'TestPageToDelete'
    page_save :page, page_name, "some content", 'create', default_user
    delete_user = user 'deleter', 'deleter@dom.org'
    page_delete :page, page_name, delete_user
    assert !page_exists?(:page, page_name)
    
    # delete page which don't exists
    assert_raise(Raki::AbstractProvider::PageNotExists) do
      page_delete :page, 'NotExistingPage', default_user
    end
  end

  # Check index for pages
  def test_page_index
    pages = {
      'page' => ['TestPage', 'TestPage2', 'TestPage3', 'TestPage4'],
      'foo' => ['TestPage', 'TestPage2', 'TestPage3', 'TestPage4'],
      'bar' => ['TestPageA', 'TestPageB', 'TestPageC', 'TestPageD']
    }
    pages.keys.each do |namespace|
      pages[namespace].each do |page_name|
        page_save namespace, page_name, "Content for page: #{page_name}", 'create', default_user
      end
    end
    namespaces.each do |namespace|
      assert pages.keys.include?(namespace)
    end
    pages.keys.each do |namespace|
      page_all(namespace).each do |page|
        assert pages[namespace].include?(page)
      end
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
    assert_same_user user1, revisions[0][:user]
    assert_equal 'create', revisions[0][:message]
    page_save :page, page_name, "updated content", 'update', user2
    revisions = page_revisions :page, page_name
    assert_equal 2, revisions.length
    assert_same_user user2, revisions[0][:user]
    assert_same_user user1, revisions[1][:user]
    assert_not_equal revisions[0][:version], revisions[1][:version]
    assert_equal 'update', revisions[0][:message]
    assert_equal 'create', revisions[1][:message]
    page_save :page, page_name, "new updated content", 'update2', user3
    revisions = page_revisions :page, page_name
    assert_equal 3, revisions.length
    assert_same_user user3, revisions[0][:user]
    assert_same_user user1, revisions[2][:user]
    assert_not_equal revisions[0][:version], revisions[2][:version]
    assert_not_equal revisions[1][:version], revisions[2][:version]
    assert_not_equal revisions[0][:version], revisions[1][:version]
    assert_equal 'update2', revisions[0][:message]
    assert_equal 'update', revisions[1][:message]
  end

  def test_attachment_exists
    page = 'TestPage'
    attachment = 'SomeFile.test'
    data = generate_binary_data
    assert !attachment_exists?(:page, page, attachment)
    attachment_save(:page, page, attachment, data, "test message", default_user)
    assert attachment_exists?(:page, page, attachment)
  end
  
  # Create a new attachment
  def test_create_attachment
    namespaces_names = [:page, :test]
    page_names = ['TestPage', 'TestPage2']
    attachment_names = ['foo.jpg', 'bar.png']
    namespaces_names.each do |namespace_name|
      page_names.each do |page_name|
        attachment_names.each do |attachment_name|
          data = generate_binary_data
          assert !attachment_exists?(namespace_name, page_name, attachment_name)
          attachment_save namespace_name, page_name, attachment_name, data, 'created', default_user
          assert attachment_exists?(namespace_name, page_name, attachment_name)
          assert_equal data, attachment_contents(namespace_name, page_name, attachment_name)
          revisions = attachment_revisions namespace_name, page_name, attachment_name
          assert_equal 1, revisions.length
          assert_same_user default_user, revisions[0][:user]
        end
      end
    end
  end
  
  # Update attachment
  def test_update_attachment
    page_name = 'TestUpdateAttachmentPage'
    attachment_name = 'foo.bar'
    old_data = generate_binary_data
    attachment_save(:page, page_name, attachment_name, old_data, 'create', default_user)
    assert_equal old_data, attachment_contents(:page, page_name, attachment_name)
    new_data = generate_binary_data
    update_user = user 'updater', 'updater@dom.org'
    attachment_save :page, page_name, attachment_name, new_data, 'update', update_user
    assert_equal new_data, attachment_contents(:page, page_name, attachment_name)
    revisions = attachment_revisions :page, page_name, attachment_name
    assert_equal 2, revisions.length
    assert_same_user default_user, revisions[1][:user]
    assert_same_user update_user, revisions[0][:user]
  end
  
  # Delete an existing attachment
  def test_delete_attachment
    page_name = 'TestPageToDeleteWithAttachment'
    attachment_name = 'foo.bar'
    attachment_save :page, page_name, attachment_name, generate_binary_data, 'update', default_user
    delete_user = user 'deleter', 'deleter@dom.org'
    attachment_delete :page, page_name, attachment_name, delete_user
    assert !attachment_exists?(:page, page_name, attachment_name)
    
    # delete page which don't exists
    assert_raise(Raki::AbstractProvider::PageNotExists) do
      attachment_delete :page, page_name, 'exists.not', delete_user
    end
  end

  private
  
  # Compare two users
  def assert_same_user(expected, actual)
    assert_equal expected.username, actual.username
    assert_equal expected.email, actual.email
  end

  # Creates a user
  def user(username, email)
    User.new(Time.new.to_s, :username => username, :email => email)
  end

  # Default user
  def default_user
    @default_user = user('testuser', 'test@user.org') if @default_user.nil?
    @default_user
  end

  def namespaces
    @provider.namespaces
  end

  def page_exists?(namespace, name, revision=nil)
    @provider.page_exists? namespace, name, revision
  end

  def page_contents(namespace, name, revision=nil)
    @provider.page_contents namespace, name, revision
  end

  def page_revisions(namespace, name)
    @provider.page_revisions namespace, name
  end

  def page_save(namespace, name, content, message, user)
    @provider.page_save namespace, name, content, message, user
  end

  def page_rename(old_namespace, old_name, new_namespace, new_name, user)
    @provider.page_rename old_namespace, old_name, new_namespace, new_name, user
  end

  def page_delete(namespace, name, user)
    @provider.page_delete namespace, name, user
  end

  def page_all(namespace)
    @provider.page_all namespace
  end

  def attachment_exists?(namespace, page, name, revision=nil)
    @provider.attachment_exists? namespace, page, name, revision
  end

  def attachment_save(namespace, page, name, contents, message, user)
    @provider.attachment_save namespace, page, name, contents, message, user
  end
  
  def attachment_contents(namespace, page, name, revision=nil)
    @provider.attachment_contents namespace, page, name, revision
  end
  
  def attachment_revisions(namespace, page, name)
    @provider.attachment_revisions namespace, page, name
  end
  
  def attachment_delete(namespace, page, name, user)
    @provider.attachment_delete namespace, page, name, user
  end

  def generate_binary_data(length=nil)
    length = 1024 + rand(4096) if length.nil?
    data = ""
    file = File.new("/dev/random", "r")
    (length/10).times do
      data += file.gets
    end
    file.close
    data
  end

end
