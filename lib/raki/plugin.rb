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

module Raki
  class Plugin

    class PluginError < StandardError
    end

    attr_reader :id

    def initialize(id)
      @id = id
    end

    def execute(&block)
      @execute = block
    end

    def execute(params, body)
      raise PluginError.new 'not implemented' if @execute.nil?
      @execute.call(params, body)
    end

    class << self
      @plugins = {}

      def register(id, &block)
        @plugins = {} if @plugins.nil?
        plugin = new(id)
        plugin.instance_eval(&block)
        @plugins[id] = plugin
      end

      def all
        @plugins
      end

      def call(id, content)
        if @plugins.key?(id.to_sym)
          plugin = @plugins[id.to_sym]
          params = {}
          body = 'test body'
          plugin.execute(params, body)
        else
          raise PluginError.new "unknown plugin (#{id})"
        end
      end

    end

  end
end
