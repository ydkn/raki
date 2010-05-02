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

Raki::Plugin.register :index do

  name 'Index plugin'
  description 'Plugin to list all wiki pages'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'

  add_stylesheet '/plugin_assets/index_plugin/stylesheets/index.css'

  execute do |params, body, context|
    rnd = rand(900)+100
    letters = {}
    Raki.provider(:page).page_all.each do |page|
      letter = page[0].chr.upcase
      letters[letter] = [] unless letters.key?(letter)
      letters[letter] << page
    end
    header = ""
    body = ""
    letters = letters.sort { |a,b| a <=> b }
    letters.each do |letter, value|
      header += "<a href=\"#INDEX-#{letter}-#{rnd}\">#{letter}</a> - "
      body += "<div class=\"index_letter\" id=\"INDEX-#{letter}-#{rnd}\">#{letter}</div><div class=\"index_pages\">"
      value.sort.each do |page|
        body += "<a href=\"/wiki/#{page}\">#{page}</a>, "
      end
      body = body[0..-3]
      body += "</div>"
    end
    "<div class=\"index\"><div class=\"index_header\">#{header[0..-4]}</div><div class=\"index_body\">#{body}</div></div>"
  end

end
