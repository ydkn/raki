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
  class Authorizer
    
    @authorizers = {}
    @authorizer = nil
    @block = []
    
    class << self
      
      def register(id, clazz)
        @authorizers[id.to_sym] = clazz
        @authorizer = clazz.new if Raki.config('authorizer') == id.to_s
      end

      def all
        @authorizers
      end
      
      def block(namespace, page)
        @block << {:namespace => namespace, :page => page}
      end

      def authorized_to?(namespace, page, action, user)
        @block.each do |block|
          return false if "#{namespace.to_s}/#{page.to_s}".match("#{(block[:namespace]+'/'+block[:page]).gsub('*', '.*')}$")
        end
        
        @authorizer.authorized_to?(namespace, page, action, user)
      end
      
      alias :self_respond_to? :respond_to?
      
      def respond_to?(method)
        #return true if self_respond_to?(method)
        @authorizer.respond_to?(method)
      end

      def method_missing(method, *args, &block)
        raise RakiError.new("No Authorizer") if @authorizer.nil?
        @authorizer.send(method, *args, &block)
      end
      private :method_missing
      
    end
    
  end
end
