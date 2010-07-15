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

  # Base class for Raki plugins.
  # Plugins are registered using the <tt>register</tt> class method that acts as the public constructor.
  #
  #   Raki::Plugin.register :example do
  #     name 'Example plugin'
  #     description 'This is an example plugin for Raki'
  #     version '0.0.1'
  #     author 'John Doe'
  #     url 'http://example.raki/plugin'
  #     execute do |params, body, context|
  #       body.reverse
  #     end
  #   end
  class Plugin

    class PluginError < StandardError
    end

    class << self
      
      private :new

      def def_field(*names)
        class_eval do
          names.each do |name|
            define_method(name) do |*args|
              args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", *args)
            end
          end
        end
      end

      # Register a plugin
      def register(id, &block)
        id = id.to_s.downcase.to_sym unless id.is_a?(Regexp)
        @plugins = {} if @plugins.nil?
        @plugins_regexp = {} if @plugins_regexp.nil?
        if (!id.is_a?(Regexp) && @plugins.key?(id)) || @plugins_regexp.key?(id)
          raise PluginError.new "A plugin with the name '#{id}' is already registred"
        end
        plugin = new(id)
        plugin.instance_eval(&block)
        if id.is_a?(Regexp)
          @plugins_regexp[id] = plugin
        else
          @plugins[id] = plugin
        end
        Rails.logger.info "Registered plugin: #{id}"
      end

      # Returns an array off all registred plugins
      def all
        (@plugins.values + @plugins_regexp.values).sort
      end

      # Executes the plugin specified by <tt>id</tt> with the give <tt>content</tt> and in the given <tt>context</tt>
      def execute(id, params, body, context={})
        id = id.to_s.downcase.to_sym
        plugin = nil
        if @plugins.key?(id)
          plugin = @plugins[id]
        else
          @plugins_regexp.each do |key, pi|
            if id =~ key
              plugin = pi
              break
            end
          end
        end
        raise PluginError.new "Unknown plugin (#{id})" if plugin.nil?
        raise PluginError.new "Plugin '#{id}' is not executable" unless plugin.executable?
        plugin.exec(id, params, body, context)
      end

      def stylesheets
        stylesheets = []
        @plugins.each do |id, plugin|
          stylesheets += plugin.stylesheets
        end
        stylesheets
      end

    end
    
    include Raki::Helpers

    def_field :name, :description, :url, :author, :version

    attr_reader :id, :stylesheets
    attr_reader :params, :body, :context, :callname
    
    def initialize(id)
      @id = id
      @stylesheets = []
    end
    
    def include(clazz)
      extend(clazz)
    end

    def add_stylesheet(url, options={})
      @stylesheets << {:url => url, :options => options}
    end

    def execute(&block)
      @execute = block
    end

    def exec(id, params, body, context={})
      @callname = id
      @params = params
      @body = body
      @context = context
      @execute.call
    end

    def executable?
      !@execute.nil?
    end
    
    def url?(url)
      !(url.match "^[a-zA-Z]+:\/\/(.+(:.+)?@)?[a-zA-Z0-9_-](\.[a-zA-Z0-9_-])*(:[0-9]+)?/").nil?
    end

  end
end
