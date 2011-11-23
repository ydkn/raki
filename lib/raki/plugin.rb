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

    class PluginError < StandardError; end
    class NotFound < PluginError; end
    class NotExecutable < PluginError; end
    class TemplateNotFound < PluginError; end
    class ExecutionError < PluginError; end

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
          raise PluginError.new "A plugin with the name '#{id}' is already registered"
        end
        plugin = new(id)
        plugin.instance_eval(&block)
        if id.is_a?(Regexp)
          @plugins_regexp[id] = plugin
        else
          @plugins[id] = plugin
        end
        Rails.logger.info "Registered plugin: #{id}"
        plugin
      end

      # Returns an array off all registred plugins
      def all
        (@plugins.values + @plugins_regexp.values).sort
      end

      # Executes the plugin specified by <tt>id</tt> with the give <tt>content</tt> and in the given <tt>context</tt>
      def execute(name, params, body, context={})
        return '' if context[:ignore_plugins]
        
        plugin = nil
        
        id = name.to_s.downcase.to_sym
        if @plugins.key?(id)
          plugin = @plugins[id]
        else
          @plugins_regexp.each do |key, pi|
            if name.to_s =~ key
              plugin = pi
              break
            end
          end
        end
        
        raise NotFound.new name.to_s unless plugin
        raise NotExecutable unless plugin.executable?
        
        begin
          plugin.exec(id, params, body, context)
        rescue => e
          Rails.logger.error(e)
          raise ExecutionError.new(e)
        end
      end

      def stylesheets
        stylesheets = []
        @plugins.each do |id, plugin|
          stylesheets += plugin.stylesheets
        end
        stylesheets
      end
      
      def templates(plugin, path)
        @templates = {} if @templates.nil?
        
        path = path.to_s
        
        return nil if path =~ /\.\./
        
        path = "#{plugin.id}/#{path}" if path.split('/', 2).length == 1
        
        if @templates.key? path
          @templates[path]
        else
          data = nil
          Dir[File.join(Rails.root, 'vendor', 'plugins', '*')].each do |plugin|
            if File.directory?(plugin)
              template = File.join(plugin, 'templates', "#{path}.erb")
              if File.exists?(template) && File.file?(template)
                data = ERB.new(File.open(template, 'r').read)
              end
            end
          end
          @templates[path] = data
        end
      end

    end
    
    include Raki::Helpers::URLHelper
    include Raki::Helpers::I18nHelper
    include Raki::Helpers::FormatHelper
    include ERB::Util

    def_field :name, :description, :url, :author, :version

    attr_reader :id, :stylesheets
    attr_reader :params, :body, :context, :callname
    
    def initialize(id)
      @id = id
      @stylesheets = []
    end
    
    def <=> b
      if name && b.name
        name <=> b.name
      else
        id.to_s <=> b.id.to_s
      end
    end
    
    def include(clazz)
      extend(clazz)
    end

    def add_stylesheet(name)
      @stylesheets << name
      Rails.application.config.assets.precompile << "#{name}.css"
    end
    
    def disable_in_live_preview(switch=true)
      @disable_in_live_preview = switch
    end
    
    def block_page(namespace, page='*')
      Raki::Authorizer.block(namespace, page)
    end

    def execute(&block)
      @execute = block
    end

    def exec(id, params, body, context={})
      if @disable_in_live_preview && context[:live_preview]
        return "<div class=\"warning\">#{I18n.t('plugin.not_available_in_live_preview')}</div>"
      end
      
      @callname = id
      @params = params
      @body = body
      
      @render = nil
      
      old_subcontext = context[:subcontext]
      context[:subcontext] = context[:subcontext].clone if context[:subcontext]
      @context = context
      
      @execute.call
      
      context[:subcontext] = old_subcontext
      
      @render = ["#{id.to_s}/#{id.to_s}"] unless @render
      if @render.is_a?(Array) && @render[0].is_a?(String)
        template = Raki::Plugin.templates(self, @render[0])
        raise TemplateNotFound.new(@render.to_s) unless template
        result = template.result(binding)
      elsif @render.is_a?(Hash)
        if @render.key?(:nothing) && @render[:nothing]
          result = nil
        elsif @render.key? :inline
          result = @render[:inline]
        end
      end
      
      result
    end

    def executable?
      !@execute.nil?
    end
    
    def parse(namespace, text)
      Raki::Parser[namespace].parse text, context
    end
    
    def render(*args)
      if args.length == 1 && args[0].is_a?(Hash)
        @render = args[0]
      else
        @render = args
      end
    end
    
    def raise(*args)
      super(PluginError.new(*args))
    end
    
    def page_for(str)
      parts = str.strip.split(/\//, 2)
      
      if parts.length == 2
        namespace = parts[0].strip
        name = parts[1].strip
      elsif !parts[0].blank? && context[:page]
        namespace = context[:page] ? context[:page].namespace : Raki.frontpage[:namespace]
        name = parts[0].strip
      elsif context[:page]
        namespace = context[:page].namespace
        name = context[:page].name
      else
        return nil
      end
      
      Page.new :namespace => namespace, :name => name
    end

  end
end
