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
  class Authenticator
    
    @authenticators = {}
    @authenticator = nil
    
    class << self
      
      def register(id, clazz)
        @authenticators[id.to_sym] = clazz
        @authenticator = clazz.new if Raki.config('authenticator') == id.to_s
      end

      def all
        @authenticators
      end
      
      alias :self_respond_to? :respond_to?
      
      def respond_to?(method)
        #return true if self_respond_to?(method)
        @authenticator.respond_to?(method)
      end

      def method_missing(method, *args, &block)
        raise RakiError.new("No Authenticator") if @authenticator.nil?
        @authenticator.send(method, *args, &block)
      end
      private :method_missing
      
    end
  end
end
