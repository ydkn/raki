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

module ApplicationHelper
  
  include Raki::Helpers::FormatHelper
  
  def meta_tag name, content
    "<meta name=\"#{h name}\" content=\"#{h content}\" />"
  end

  def plugin_stylesheets
    stylesheets = []
    Raki::Plugin.stylesheets.each do |stylesheet|
      stylesheets << stylesheet_link_tag(stylesheet[:url], stylesheet[:options])
    end
    stylesheets.join ""
  end
  
  def authenticated?
    return false if User.current.is_a? AnonymousUser
    User.current.is_a? User
  end
  
  def visited_pages
    @visited_pages ||= session[:visited_pages].collect{|p| Page.new :namespace => p[:namespace], :name => p[:page]}
  end

end
