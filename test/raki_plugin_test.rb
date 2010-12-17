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

module Raki
  module Test
    module Plugin
      class TestCase < ::Test::Unit::TestCase
        
        def self.plugin_id(id=nil)
          @plugin_id = id if id
          @plugin_id ||= self.to_s.gsub(/Test$/, '').gsub(/Plugin$/, '').underscore.to_sym
        end
        
        private
        
        def default_test
        end

        def register(id, &block)
          Raki::Plugin.register(id, &block)
        end
        
        def plugin(id=self.class.plugin_id)
          Raki::Plugin.all.select{|p| p.id == id}.first
        end
        
        def exec(params, body, context={}, callname=self.class.plugin_id)
          plugin.exec(callname.to_s, params, body, context)
        end
        
        def assert_raise_plugin_error(error_msg, *args, &block)
          error = nil
          assert_raise(Raki::Plugin::PluginError) do
            begin
              block.call
            rescue => e
              error = e
              raise e
            end
          end
          assert_equal error_msg, error.to_s, *args
        end

      end
    end
  end
end
