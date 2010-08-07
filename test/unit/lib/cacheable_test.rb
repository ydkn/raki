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
  
  class TestCache
    include Cacheable
    def cached_method
      @test.nil? ? @test = 0 : @test += 1
      @test
    end
    cache :cached_method, :ttl => 3
  end
  
  def test_refresh
    cached = TestCache.new
    5.times do |i|
      assert_equal i, cached.cached_method
      sleep 1
      assert_equal i, cached.cached_method
      sleep 2
      assert_equal i, cached.cached_method
      sleep 1
    end
  end
  
end
