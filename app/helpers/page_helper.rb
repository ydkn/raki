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
  
  def url_for_page(type, name, revision=nil)
    if revision.nil?
      {:controller => 'page', :action => 'view', :type => h(type), :id => h(name)}
    else
      {:controller => 'page', :action => 'view', :type => h(type), :id => h(name), :revision => h(revision)}
    end
  end
  
  def authorized?(type, name, action)
    Raki::Permission.to?(type, name, action, User.current)
  end

  def page_contents(type, name, revision=nil)
    if authorized?(type, name, :view) && page_exists?(type, name, revision)
      Raki::Provider[type].page_contents(type, name, revision)
    else
      return nil
    end
  end

  def insert_page(type, name, revision=nil)
    if authorized?(type, name, :view) && page_exists?(type, name, revision)
      context = @context.clone
      context[:type] = type
      context[:page] = name
      begin
        parsed = Raki::Parser[type].parse(page_contents(type, name, revision), context)
        parsed.nil? ? "<div class=\"error\">#{t 'parser.parsing_error'}</div>" : parsed
      rescue => e
        Rails.logger.error e
        "<div class=\"error\">#{t 'parser.parsing_error'}</div>"
      end
    end
  end

  def page_exists?(type, name, revision=nil)
    if authorized?(type, name, :view)
      Raki::Provider[type].page_exists?(type, name, revision)
    else
      false
    end
  end

  def page_revisions(type, name)
    if authorized?(type, name, :view)
      Raki::Provider[type].page_revisions(type, name)
    else
      nil
    end
  end

end
