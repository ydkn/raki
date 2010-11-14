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

class PluginTest < Test::Unit::TestCase
  
  # Test custom raise
  def test_raise
    plugin = register :raise_test do
      execute do
        raise 'error-message'
      end
    end
    
    assert_raise(Raki::Plugin::PluginError) do
      plugin.exec(:raise_test, {}, '', {})
    end
    
    begin
      plugin.exec(:raise_test, {}, '', {})
    rescue => e
      assert_equal e.to_s, 'error-message'
    end
  end
  
  private
  
  def register(id, &block)
    Raki::Plugin.register(id, &block)
  end
  
  def plugin(id)
    Raki::Plugin.all.select{|p| p.id == id}.first
  end
  
end
