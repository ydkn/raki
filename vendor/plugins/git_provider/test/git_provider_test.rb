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
    `git init #{Rails.root}/tmp/test/git-repo`
    @provider = GitProvider.new({'path' => "#{Rails.root}/tmp/test/git-repo"})
  end

  # Remove GIT repository after testing
  def teardown
    `rm -rf #{Rails.root}/tmp/test/git-repo`
  end

  # Create a new page
  def test_create_page
    page_name = 'TestPage'
    user = User.new(:username => 'TestUser', :email => 'test@user.com')
    @provider.save_page(page_name, "test content 123", user, 'changed')
    assert(@provider.page_exists?(page_name), "Failed to created page.")
  end

  # Update page contents
  def test_update_page
    page_name = 'TestPage'
    user = User.new(:username => 'TestUser', :email => 'test@user.com')
    old_content = @provider.page_contents(page_name)
    @provider.save_page(page_name, "987 test content", user, 'changed')
    new_content = @provider.page_contents(page_name)
    assert(new_content != old_content, "Failed to update page.")
  end
end
