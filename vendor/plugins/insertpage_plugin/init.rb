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
      namespace = parts[0].strip.to_sym
      page = parts[1].strip
    else
      namespace = context[:namespace]
      page = parts[0].nil? ? nil : parts[0].strip
    end
    key = [namespace, page]
    
    raise Raki::Plugin::PluginError.new(t 'insertpage.no_page') if page.nil? || page.empty?
    
    if authorized? namespace, page, :view
      raise Raki::Plugin::PluginError.new(t 'page.not_exists.msg') unless page_exists? namespace, page

      context[:subcontext][:insertpage] ||= []
      raise Raki::Plugin::PluginError.new(t 'insertpage.already_included', :name => page) if context[:subcontext][:insertpage].include? key
      context[:subcontext][:insertpage] << key

      context[:namespace] = namespace
      context[:page] = page

      parsed_page!(namespace, page)
    else
      ""
    end
  end

end
