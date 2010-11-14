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
  class AbstractAuthenticator

    class AuthenticatorError < StandardError
    end
    
    def user_for(options)
      raise AuthenticatorError.new 'not implemented'
    end
    
    #def callback(params, session, cookies)
    #  raise AuthenticatorError.new 'not implemented'
    #end

    #def login(params, session, cookies)
    #  raise AuthenticatorError.new 'not implemented'
    #end
    
    #def logout(params, session, cookies)
    #  raise AuthenticatorError.new 'not implemented'
    #end
    
    #def validate_session(params, session, cookies)
    #  raise AuthenticatorError.new 'not implemented'
    #end
    
    #def form_fields
    #  raise AuthenticatorError.new 'not implemented'
    #end

  end
end
