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

class GitRepoTest < Test::Unit::TestCase
  
  def test_repo
    repo_path = File.join(Rails.root, 'tmp', 'test-git-repo')
    `git init --bare #{repo_path}`
    
    assert GitRepo.new(repo_path)
    assert_raise(GitRepo::InvalidRepository) do
      GitRepo.new(File.join(Rails.root, 'tmp', 'test-git-repo-inexistent'))
    end
  end
  
end
