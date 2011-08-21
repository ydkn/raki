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
      
      include ERB::Util
      
      class << self
        attr_accessor :host, :port
      end
      
      include ActionView::Helpers::UrlHelper
      include ActionController::UrlWriter
      
      def self.included base
        base.extend ClassMethods
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
      
      def url_for_page namespace, page, revision=nil, action='view', options={}
        options[:controller] = 'page'
        options[:action] = action.to_s
        options[:namespace] = h namespace.to_s
        options[:page] = h page.to_s
        options[:revision] = h revision.to_s if revision
        
        url_for_options options
      end
      
      def url_for_options options
        opts = {}
        options.each do |k,v|
          if v.respond_to?(:html_safe?) && !v.html_safe?
            opts[k] = h v
          else
            opts[k] = v
          end
        end
        
        url_for options
      end

    end
    
  end
end
