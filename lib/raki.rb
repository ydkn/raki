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
  class << self

    attr_reader :controller
    
    def init(controller)
      @controller = controller
    end

    def config(*keys)
      @config = YAML.load(File.read("#{Rails.root}/config/raki.yml")) if @config.nil?
      @requested_config = @config
      keys.each do |key,value|
        @requested_config = @requested_config[key]
      end
      @requested_config
    end

    def frontpage
      return config[:frontpage] unless config[:frontpage].nil?
      'Main'
    end

    def app_name
      'Raki'
    end

    def version
      '0.1pre'
    end

    def register_provider(id, clazz)
      @providers = {} if @providers.nil?
      @providers[id] = clazz
    end

    def providers
      @providers
    end

    def provider(type)
      if @current_provider.nil?
        c = config('providers', type.to_s)
        id = c['provider']
        c.delete('provider')
        @current_provider = @providers[id.to_sym].new(c)
      end
      @current_provider
    end

    def register_parser(id, clazz)
      @parsers = {} if @parsers.nil?
      @parsers[id] = clazz
    end

    def parsers
      @parsers
    end

    def parser(type)
      if @current_parser.nil?
        c = config('parsers', type.to_s)
        id = c['parser']
        c.delete('parser')
        @current_parser = @parsers[id.to_sym].new(c)
      end
      @current_parser
    end

    def register_authenticator(id, clazz)
      @authenticators = {} if @authenticators.nil?
      @authenticators[id] = clazz
    end

    def authenticators
      @authenticators
    end

    def authenticator
      if @current_authenticator.nil?
        id = config('authenticator')
        @current_authenticator = @authenticators[id.to_sym].new
      end
      @current_authenticator
    end

  end
end
