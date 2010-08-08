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

require 'raki/permission'
require 'raki/provider'
require 'raki/parser'
require 'raki/authenticator'
require 'raki/plugin'

module Raki
  
  class RakiError < StandardError
  end
  
  class << self
    
    VERSION = '0.1pre'
    
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
    
    def app_name
      return config(:app_name) unless config(:frontpage).nil?
      'Raki'
    end
    
    def frontpage
      return {:type => 'page', :page => 'Main'} if config(:frontpage).nil?
      parts = config(:frontpage).split('/', 2)
      if parts.length == 2
        {:type => parts[0], :page => parts[1]}
      else
        {:type => 'page', :page => parts[0]}
      end
    end
    
    def userpage_type
      return config(:userpage_type) unless config(:userpage_type).nil?
      'user'
    end
    
    def index_page
      return config(:index_page) unless config(:index_page).nil?
      'Main'
    end
    
    def version
      VERSION
    end

  end
end
