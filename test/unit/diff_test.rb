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

class DiffTest < Test::Unit::TestCase
  
  def test_create_from_pages
    p1 = Page.new :namespace => 'test', :name => 'page'
    p1.content = 'foo'
    p2 = Page.new :namespace => 'test', :name => 'page'
    p2.content = 'bar'
    
    diff = Diff.create p1, p2
    
    assert_equal p1, diff.from
    assert_equal p2, diff.to
    assert_equal 2, diff.lines.length
    assert_equal :remove, diff.lines[0].type
    assert_equal 'foo', diff.lines[0].line
    assert_equal :add, diff.lines[1].type
    assert_equal 'bar', diff.lines[1].line
  end
  
end
