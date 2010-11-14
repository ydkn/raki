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
  module Helpers
    
    module AuthorizationHelper
      
      class NotAuthorizedError < StandardError
      end
      
      def authorized?(namespace, name, action, user=User.current)
        if action.is_a?(Array)
          action.each do |a|
            return true if Raki::Authorizer.authorized_to?(namespace, name, a, user)
          end
          false
        else
          Raki::Authorizer.authorized_to?(namespace, name, action, user)
        end
      end

      def authorized!(namespace, name, action, user=User.current)
        unless authorized?(namespace, name, action, user)
          raise NotAuthorizedError.new "#{user.id.to_s} has no permission to #{action.to_s} #{namespace.to_s}/#{name.to_s}"
        end
        true
      end

    end
    
  end
end
