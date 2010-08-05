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
  class << self
    
    VERSION = '0.1pre'
    
    class RakiError < StandardError
    end
    
    def config(*keys)
      @config = YAML.load(File.read("#{Rails.root}/config/raki.yml")) if @config.nil?
      requested_config = @config
      keys.each do |key,value|
        key = key.to_s
        return nil if requested_config[key].nil?
        requested_config = requested_config[key]
      end
      requested_config
    end
    
    def frontpage
      return config(:frontpage) unless config(:frontpage).nil?
      'Main'
    end
    
    def app_name
      return config(:app_name) unless config(:frontpage).nil?
      'Raki'
    end
    
    def userpage_type
      return config(:userpage_type) unless config(:userpage_type).nil?
      'user'
    end
    
    def version
      VERSION
    end
    
    attr_reader :providers, :initialized_providers
    
    def register_provider(id, clazz)
      @providers = {} if @providers.nil?
      @initialized_providers = {} if @initialized_providers.nil?
      @providers[id.to_sym] = clazz
      config('providers').each do |type, settings|
        if settings['provider'] == id.to_s
          @initialized_providers[type.to_sym] = clazz.new(settings)
        end
      end
    end
    
    def provider(type)
      type = type.to_sym
      unless @initialized_providers.key?(type)
        return @initialized_providers[:default] if @initialized_providers.key?(:default)
        raise RakiError.new("No Provider")
      end
      @initialized_providers[type]
    end
    
    attr_reader :parsers, :initialized_parsers
    
    def register_parser(id, clazz)
      @parsers = {} if @parsers.nil?
      @initialized_parsers = {} if @initialized_parsers.nil?
      @parsers[id.to_sym] = clazz
      config('parsers').each do |type, settings|
        if settings['parser'] == id.to_s
          @initialized_parsers[type.to_sym] = clazz.new(settings)
        end
      end
      
    end
    
    def parser(type)
      type = type.to_sym
      unless @initialized_parsers.key?(type)
        return @initialized_parsers[:default] if @initialized_parsers.key?(:default)
        raise RakiError.new("No Parser")
      end
      @initialized_parsers[type]
    end
    
    attr_reader :authenticators, :authenticator
    
    def register_authenticator(id, clazz)
      @authenticators = {} if @authenticators.nil?
      @authenticators[id.to_sym] = clazz
      @authenticator = clazz.new if config('authenticator') == id.to_s
    end
    
    def permissions
      if @permissions.nil?
        @permissions = YAML.load(File.read("#{Rails.root}/config/permissions.yml"))
        unless @permissions.key?(:OVERWRITE)
          @permissions[:OVERWRITE] = []
        end
      end
      @permissions
    end
    
    def permission?(type, page, action, user)
      perms = permissions[:ALL]
      if user.is_a?(AnonymousUser)
        perms = perms + permissions[:ANONYMOUS]
      elsif user.is_a?(User)
        perms = perms + permissions[:AUTHENTICATED]
      end
      perms = perms + permissions[:OVERWRITE]
      
      permissions.each do |u_key, rights|
        next if u_key.is_a?(Symbol)
        next if user.id.match("^#{u_key}$").nil?
        perms += rights
      end
      
      perm = false
      perms.each do |right|
        right = right.first
        next if "#{type.to_s}/#{page.to_s}".match("^#{right[0].gsub('*', '.*')}$").nil?
        rights = right[1].split(',')
        rights.map {|r| r.to_s.strip}
        perm = true if rights.include?('all')
        perm = false if rights.include?('!all')
        perm = true if rights.include?(action.to_s)
        perm = false if rights.include?("!#{action.to_s}")
      end
      
      perm
    end
    
    def permission_overwrite(type, page, rights)
      rights = [rights] unless rights.is_a?(Array)
      rights.map {|r| r.to_s.strip}
      permissions[:OVERWRITE] << {"#{type.to_s}/#{page.to_s}" => rights.join(',')}
    end

  end
end
