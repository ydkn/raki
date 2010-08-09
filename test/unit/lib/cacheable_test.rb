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
    def initialize
      @m1 = @m2 = -1
      @m3 = Hash.new{|h,k| h[k] = -1}
    end
    def m1
      @m1 += 1
      @m1
    end
    cache :m1, :ttl => 3
    def m2
      @m2 += 1
      @m2
    end
    cache :m2, :ttl => 3, :force => true
    def m3(p1)
      @m3[p1] += 1
      @m3[p1]
    end
    cache :m3, :ttl => 3
  end
  
  # Test if method is cached.
  def test_refresh
    cached = TestCache.new
    5.times do |i|
      assert_equal i, cached.m1
      assert_equal i, cached.m2
      assert_equal i, cached.m3(1)
      assert_equal i, cached.m3(2)
      sleep 1
      assert_equal i, cached.m1
      assert_equal i, cached.m2
      assert_equal i, cached.m3(1)
      assert_equal i, cached.m3(2)
      sleep 2
      assert_equal i, cached.m1
      assert_equal (i+1), cached.m2
      assert_equal i, cached.m3(1)
      assert_equal i, cached.m3(2)
      sleep 1
    end
  end
  
  # Test if cached? returns correct state.
  def test_cached
    cached = TestCache.new
    
    # force = false
    assert !cached.cached?(:m1)
    cached.m1
    assert cached.cached?(:m1)
    sleep 4
    assert cached.cached?(:m1)
    
    # force = true
    assert !cached.cached?(:m2)
    cached.m2
    sleep 1
    assert cached.cached?(:m2)
    sleep 3
    assert !cached.cached?(:m2)
  end
  
end
