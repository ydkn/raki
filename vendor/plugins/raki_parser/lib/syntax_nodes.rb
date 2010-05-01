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

class IgnoreNode < Treetop::Runtime::SyntaxNode
  def to_html
    ''
  end
end

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
    return '<span class="underline">' + text.to_html + '</span>'
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
    return "<h#{l}>" + text.to_html.strip + "</h#{l}>\n"
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

    items = [first_item]
    other_items.elements.each do |other|
      items += [other.item]
    end

    @lists = []
    out = ''

    items.each do |item|
      out += adapt item.level.text_value.length + 1, item.type.text_value
      out += '<li>'
      out += item.text.to_html
    end
    out += adapt 0, ''
   end

  private

  def adapt level, type
    diff = level - @lists.size
    parameter = ''
    out = ''

    if type == '#'
      type = 'ol'
    elsif type == '*'
      type = 'ul'
    elsif type == '-'
      type = 'ul'
      parameter = 'class="line"'
    else
       type = ''
    end

    if diff > 0
      (1..diff).each do
        out += "\n" unless @lists.empty?
        if parameter.empty?
          out += "<#{type}>\n"
        else
          put +=  "<#{type} class=\"#{parameter}\">\n"
        end
        @lists = @lists << type
      end
    elsif diff < 0
      (diff..-1).each do
        out += "</li>\n</#{@lists.slice!(-1)}>\n"
      end
      out += "</li>\n" unless @lists.empty?
    else
      out += "</li>\n"
    end


    if type != @lists[-1] && level != 0
      out += "</#{@lists.slice!(-1)}>\n"
      out += "<#{type}>\n"
      @lists = @lists << type
    end
    out
  end
end

class PluginNode < Treetop::Runtime::SyntaxNode
  def to_html
    @@coder = HTMLEntities.new unless defined? @@coder
    begin
      if defined? body and !body.nil?
        text = body.text_value
      else
        text = ''
      end
      params = Hash[]
      if defined? param
        param.elements.each do |element|
          params = params.merge element.parameter.keyval
        end
      end
      Raki::Plugin.execute(name.text_value, params, text, {}).to_s
    rescue => e
      "<div class=\"error\">#{@@coder.encode e.to_s}</div>"
    end
  end
end

class ParameterNode < Treetop::Runtime::SyntaxNode
  def keyval
    val = value.text_value
    if val[0] == '"' && val[-1] == '"';
      val = val[1..-2].gsub(/\"/, '"')
    elsif val[0] == "'" && val[-1] == "'";
      val = val[1..-2].gsub(/\'/, "'")
    end
    Hash[key.text_value.to_sym, val]
  end
end