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

module PageHelper
  
  include Raki::Helpers::AuthorizationHelper
  include Raki::Helpers::ProviderHelper
  include Raki::Helpers::ParserHelper
  
  def url_for_page namespace, page, revision=nil
    if revision.nil?
      url_for :controller => 'page', :action => 'view', :namespace => h(namespace), :page => h(page)
    else
      url_for :controller => 'page', :action => 'view', :namespace => h(namespace), :page => h(page), :revision => h(revision)
    end
  end

  def insert_page namespace, page, revision=nil
    if authorized?(namespace, page, :view) && page_exists?(namespace, page, revision)
      context = @context.clone
      context[:namespace] = namespace
      context[:page] = page
      begin
        contents = page_contents namespace, page, revision
        parsed = parse namespace, contents, context
      rescue => e
        Rails.logger.error e
        "<div class=\"error\">#{t 'parser.parsing_error'}</div>"
      end
    end
  end

end
