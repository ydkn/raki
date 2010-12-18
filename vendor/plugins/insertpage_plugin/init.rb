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

Raki::Plugin.register :insertpage do

  name 'Insert page plugin'
  description 'Plugin to insert a page into another'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'

  execute do
    parts = body.strip.split /\//, 2
    if parts.length == 2
      namespace = parts[0].strip
      page = parts[1].strip
    else
      namespace = context[:page] ? context[:page].namespace : Raki.frontpage[:namespace]
      page = parts[0] ? parts[0].strip : nil
    end
    key = [namespace, page]
    
    page = Page.new :namespace => namespace, :name => page
    
    raise t('insertpage.no_page') unless page
    
    if page.authorized?(User.current, :view)
      raise t('insertpage.not_exists', :namespace => h(page.namespace), :name => h(page.name)) unless page.exists?

      context[:subcontext][:insertpage] ||= []
      raise t('insertpage.already_included', :namespace => h(page.namespace), :name => h(page.name)) if context[:subcontext][:insertpage].include? key
      
      context[:subcontext][:insertpage] << key
      context[:page] = page
      
      render :inline => page.render(context)
    else
      render :nothing => true
    end
  end

end
