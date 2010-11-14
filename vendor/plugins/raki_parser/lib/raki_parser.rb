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

require 'treetop'
require 'syntax_nodes.rb'

class RakiParser < Raki::AbstractParser

  def logger
    Rails.logger
  end

  def initialize params={}
    Treetop.load "#{File.dirname(__FILE__)}/raki_syntax"
    if Rails.env != 'test'
      RakiSyntaxParser.send :include, Cacheable
      RakiSyntaxParser.send :cache, :parse
    end
    @parser = RakiSyntaxParser.new
  end

  def parse text, context={}
    output = @parser.parse text
    return nil if output.nil?
    output.to_html(context)
  end

  def src text, context={}
    output = @parser.parse text
    return text if output.nil?
    output.to_src(context)
  end

  def link_update text, from, to, context={}
    output = @parser.parse text
    return text if output.nil?
    output.link_update from, to, context
    output.to_src(context)
  end

end
