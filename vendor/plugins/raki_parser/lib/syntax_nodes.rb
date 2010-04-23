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

require 'htmlentities'

module HTMLSyntax
  def to_html
    @@coder = HTMLEntities.new unless defined? @@coder
    output = ''
    unless elements.nil?
      elements.each do |e|
        unless e.elements.nil?
          output += e.to_html
        else
          output += @@coder.encode e.text_value
        end
      end
    end
    output
  end
end

Treetop::Runtime::SyntaxNode.send(:include, HTMLSyntax)

class LinebreakNode < Treetop::Runtime::SyntaxNode
  def to_html
    "<br/>\n"
  end
end

class LinkNode < Treetop::Runtime::SyntaxNode
  def to_html
    return '<a href="' + href.to_html.strip + '">' +
      (desc.to_html.empty? ? href : desc).to_html.strip + '</a>'
  end
end

class WikiLinkNode < Treetop::Runtime::SyntaxNode
  def to_html
    return '<a href="/wiki/' + href.to_html.strip + '">' +
      (desc.to_html.empty? ? href : desc).to_html.strip + '</a>'
  end
end

class BoldNode < Treetop::Runtime::SyntaxNode
  def to_html
    return '<b>' + text.to_html + '</b>'
  end
end

class ItalicNode < Treetop::Runtime::SyntaxNode
  def to_html
    return '<i>' + text.to_html + '</i>'
  end
end

class UnderlineNode < Treetop::Runtime::SyntaxNode
  def to_html
    return '<u>' + text.to_html + '</u>'
  end
end

class StrikethroughNode < Treetop::Runtime::SyntaxNode
  def to_html
    return '<del>' + text.to_html + '</del>'
  end
end

class HeadingNode < Treetop::Runtime::SyntaxNode
  def to_html
    l = level.text_value.length
    l = 6 if l > 6
    return "<h#{l}>" + text.to_html.strip + "</h#{l}>"
  end
end

class InfoboxNode < Treetop::Runtime::SyntaxNode
  def to_html
    '<div class="' + type.to_html + '">' + text.to_html.strip + '</div>'
  end
end

class ListNode < Treetop::Runtime::SyntaxNode

  @lists

  def to_html
    @lists = []
    out = ''
    elements.each do |row|
      row.elements.each do |item|
        if item.respond_to? 'level'
          out += adapt item.level.text_value.length + 1, item.type.text_value
          out += '<li>' + item.text.to_html.strip + "</li>\n"
        end
      end
    end
    out += adapt 0, ''
  end

  private

  def adapt level, type
    diff = level - @lists.size
    if type == '#'
      type = 'ol'
    else type == '*'
      type = 'ul'
    end

    out = ''
    if diff > 0
      (1..diff).each do
        out += "<#{type}>\n"
        @lists = @lists << type
      end
    elsif diff < 0
      (diff..-1).each do
         out += "</#{@lists.slice!(-1)}>\n"
      end
    end

    if type != @lists[-1] && level != 0
      out += "</#{@lists.slice!(-1)}>\n"
      out += "<#{type}>"
      @lists = @lists << type
    end
    out
  end
end
