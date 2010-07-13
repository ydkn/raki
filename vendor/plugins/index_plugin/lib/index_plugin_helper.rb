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

class IndexPluginHelper
  class << self
    include Raki::Helpers

    def build(params, body, context)
      type = params[:type].nil? ? :page : params[:type].to_sym
      rnd = rand(900)+100
      letters = {}
      Raki.provider(type).page_all(type).each do |page|
        letter = page[0].chr.upcase
        letters[letter] = [] unless letters.key?(letter)
        letters[letter] << page
      end
      header = ""
      content = ""
      letters = letters.sort { |a,b| a <=> b }
      letters.each do |letter, value|
        header += "<a href=\"#INDEX-#{h(letter)}-#{rnd}\">#{h(letter)}</a> - "
        content += "<div class=\"index_letter\" id=\"INDEX-#{h(letter)}-#{rnd}\">#{h(letter)}</div><div class=\"index_pages\">"
        value.sort.each do |page|
          content += "<a href=\"#{url_for(:controller => 'page', :action => 'view', :type => h(type), :id => h(page))}\">#{h(page)}</a>, "
        end
        content = content[0..-3]
        content += "</div>"
      end
      "<div class=\"index\"><div class=\"index_header\">#{header[0..-4]}</div><div class=\"index_body\">#{content}</div></div>"
    end

  end
end
