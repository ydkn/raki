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

  def page_contents(type, name, revision=nil)
    Raki.provider(type).page_contents(type, name, revision)
  end

  def insert_page(type, name, revision=nil)
    if page_exists?(type, name, revision)
      context = @context.clone
      context[:type] = type
      context[:page] = name
      parsed = Raki.parser(type).parse(page_contents(type, name, revision), context)
      parsed.nil? ? "<div class=\"error\">PARSING ERROR</div>" : parsed
    end
  end

  def page_exists?(type, name, revision=nil)
    Raki.provider(type).page_exists?(type, name, revision)
  end

  def page_revisions(type, name)
    Raki.provider(type).page_revisions(type, name)
  end

end
