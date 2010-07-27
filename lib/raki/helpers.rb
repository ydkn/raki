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

    include ERB::Util
    include ActionView::Helpers::UrlHelper

    class << self
      attr_reader :controller
      def init(controller)
        @controller = controller
      end
    end

    def t(*args)
      Raki::Helpers.controller.t(*args)
    end

    def l(*args)
      Raki::Helpers.controller.l(*args)
    end

    def url_for(*args)
      Raki::Helpers.controller.url_for(*args)
    end
    
    def redirect_to(*args)
      Raki::Helpers.controller.send(:redirect_to, *args)
    end

  end
end
