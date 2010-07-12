# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
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

  execute do |params, body, context|
    type = :page
    raise Raki::Plugin::PluginError.new(t 'plugin.missing_parameter') if params[:name].nil?
    context[:insertpage] = [] if context[:insertpage].nil?
    raise Raki::Plugin::PluginError.new(t 'insertpage.already_included') if context[:insertpage].include? params[:name]
    context[:insertpage] << params[:name]
    Raki.parser(type).parse(
      Raki.provider(type).page_contents(type, params[:name]),
      context
    )
  end

end
