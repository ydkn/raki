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
    
    module URLHelper
      
      class << self
        attr_accessor :host, :port
      end
      
      include ActionView::Helpers::UrlHelper
      include ActionController::UrlWriter
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        
        def default_url_options
          {
            :host => Raki::Helpers::URLHelper.host,
            :port => Raki::Helpers::URLHelper.port,
            :only_path => true
          }
        end
        
      end

    end
    
  end
end
