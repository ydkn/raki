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
  class Provider
    
    @providers = {}
    @initialized = {}
    
    class << self
      
      def register(id, clazz)
        @providers[id.to_sym] = clazz
        Raki.config('providers').each do |type, settings|
          if settings['provider'] == id.to_s
            @initialized[type.to_sym] = clazz.new(settings)
          end
        end
      end

      def [](type)
        type = type.to_sym
        unless @initialized.key?(type)
          return @initialized[:default] if @initialized.key?(:default)
          raise RakiError.new("No Provider")
        end
        @initialized[type]
      end

      def all
        @providers
      end

      def used
        @initialized
      end
      
    end
  end
end
