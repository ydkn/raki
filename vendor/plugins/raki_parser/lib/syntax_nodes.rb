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

class RakiSyntaxNode < Treetop::Runtime::SyntaxNode
  
  include Raki::Helpers::URLHelper
  include ERB::Util
  
end

class IgnoreNode < RakiSyntaxNode
  
  def to_html context
    ''
  end
  
end


class LinebreakNode < RakiSyntaxNode
  
  def to_html context
    "<br/>\n"
  end
  
end


class LinkNode < RakiSyntaxNode
  
  @@dangerous_protocols = ['about', 'wysiwyg', 'data', 'view-source', 'ms-its', 'mhtml', 'shell', 'lynxexec',  'lynxcgi', 'hcp', 'ms-help', 'help', 'disk', 'vnd.ms.radio', 'opera', 'res', 'resource',  'chrome', 'mocha', 'livescript', 'javascript', 'vbscript']

  def to_html context
    if @@dangerous_protocols.include? href.protocol.to_html(context).strip
      '<a target="_blank" href="' + href.to_html(context).strip + '">' +
      (desc.to_html(context).empty? ? href : desc).to_html(context).strip + '</a>'
    else
      '<a href="' + href.to_html(context).strip + '">' +
      (desc.to_html(context).empty? ? href : desc).to_html(context).strip + '</a>'
    end
  end
  
end


class WikiLinkNode < RakiSyntaxNode
  
  def to_html context
    parts = href.text_value.split '/'
    if parts.length == 2
      type = parts[0]
      page = parts[1]
    else
      type = context[:type]
      page = parts[0]
    end
    pagelink = url_for_page h(type.strip), h(page.strip)
    return '<a href="' + pagelink + '">' +
      (desc.to_html(context).empty? ? href.to_html(context) : desc.to_html(context).strip).strip + '</a>'
  end

end


class BoldNode < RakiSyntaxNode
  
  def to_html context
    return '<b>' + text.to_html(context) + '</b>'
  end
  
end


class ItalicNode < RakiSyntaxNode
  
  def to_html context
    return '<i>' + text.to_html(context) + '</i>'
  end
  
end


class UnderlineNode < RakiSyntaxNode
  
  def to_html context
    return '<span class="underline">' + text.to_html(context) + '</span>'
  end
end


class StrikethroughNode < RakiSyntaxNode
  
  def to_html context
    return '<del>' + text.to_html(context) + '</del>'
  end
  
end


class HeadingNode < RakiSyntaxNode
  
  def to_html context
    l = level.text_value.length
    l = 6 if l > 6
    return "<h#{l}>" + text.to_html(context).strip + "</h#{l}>\n"
  end
  
end


class InfoboxNode < RakiSyntaxNode
  
  def to_html context
    '<div class="' + type.to_html(context) + '">' + text.to_html(context).strip + '</div>'
  end
  
end


class ListNode < RakiSyntaxNode

  def to_html context

    items = [first_item]
    other_items.elements.each do |other|
      items += [other.item]
    end

    @lists = []
    out = ''

    items.each do |item|
      out += adapt item.level.text_value.length + 1, item.type.text_value
      out += '<li>'
      out += item.text.to_html context
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
          out +=  "<#{type} #{parameter}>\n"
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


class PluginNode < RakiSyntaxNode
  
  include Raki::Helpers::I18nHelper
  
  def to_html context
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
      begin
        Raki::Plugin.execute(name.text_value, params, text, context).to_s
      rescue Raki::Plugin::PluginError => pe
        "<div class=\"error\"><b>#{h pe.to_s}</b></div>"
      end
    rescue => e
      Rails.logger.error "Plugin '#{name.text_value}' caused error (#{e.class}): #{e.to_s}\n#{e.backtrace.join "\n"}"
      "<div class=\"error\"><b>#{t 'plugin.error', :name => name.text_value}</b></div>"
    end
  end
  
end


class ParameterNode < RakiSyntaxNode
  
  def keyval
    val = value.text_value
    if val[0] == '"' && val[-1] == '"';
      val = val[1..-2].gsub(/\\"/, '"')
    elsif val[0] == "'" && val[-1] == "'";
      val = val[1..-2].gsub(/\\'/, "'")
    end
    Hash[key.text_value.to_sym, val]
  end
  
end


class TableNode < RakiSyntaxNode
  
  def to_html context
    out = "<table class=\"wikitable\">\n"
    out += "<tr>" + first_row.to_html(context) + "</tr>\n"
    other_rows.elements.each do |row|
      out += "<tr>" + row.to_html(context) + "</tr>\n"
    end
    out += "</table>\n"
  end
  
end


class TableRowNode < RakiSyntaxNode
  
  def to_html context
    out = ''
    is_head_row = !head_row.text_value.empty?
    cells.elements.each do |cell|
      if is_head_row || !cell.head.text_value.empty?
        out += "<th>" + cell.data.to_html(context) + "</th>\n"
      else
        out += "<td>" + cell.data.to_html(context) + "</td>\n"
      end
    end
    out
  end
  
end
