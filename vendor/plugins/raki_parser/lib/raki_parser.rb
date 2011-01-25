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
    return nil unless output
    output.to_html(context).html_safe
  rescue => e
    Rails.logger.error(e)
    raise ParserError.new(e)
  end
  
  def link_update text, from, to, context={}
    output = @parser.parse text
    return [nil, nil] unless output
    if output.link_update(from, to, context)
      [true, output.to_src(context)]
    else
      [false, text]
    end
  end
  
  def sections text, context={}
    output = @parser.parse text
    output.sections context
  end
  
  def toolbar_items
    [
      [
        {:id => 'link', :prefix => '[', :suffix => ']'},
        {:id => 'heading1', :'line-start' => '!'},
        {:id => 'heading2', :'line-start' => '!!'},
        {:id => 'heading3', :'line-start' => '!!!'}
      ],
      [
        {:id => 'bold', :enclosed => '*'},
        {:id => 'italic', :enclosed => '~'},
        {:id => 'underline', :enclosed => '_'},
        {:id => 'strike', :enclosed => '-'}
      ],
      [
        {:id => 'hline', :line => '----'}
      ],
      [
        {:id => 'orderedlist', :'multiline-start' => '# '},
        {:id => 'list', :'multiline-start' => '* '},
      ]
    ]
  end
  
  private
  
  def src text, context={}
    output = @parser.parse text
    return nil unless output
    output.to_src(context)
  end

end
