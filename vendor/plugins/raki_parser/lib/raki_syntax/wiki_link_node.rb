# Raki - extensible rails-based wiki
# Copyright (C) 2011 Florian Schwab & Martin Sigloch
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

class RakiSyntax::WikiLinkNode < RakiSyntax::Node

  def to_html context
    @context = context
    
    t = target
    
    if !t || (!t.url rescue true)
      "<span class=\"invalid-page\">#{h title}</span>"
    elsif t.exists? && t.is_a?(Attachment) && t.mime_type =~ /^image\//i
      "<a href=\"#{t.url}\" title=\"#{h title}\"><img src=\"#{t.url}\" alt=\"#{h title}\" title=\"#{h title}\"/></a>"
    elsif t.exists?
      "<a href=\"#{t.url}\" title=\"#{h title}\">#{h title}</a>"
    else
      "<a class=\"inexistent\" href=\"#{t.url}\" title=\"#{h title}\">#{h title}</a>"
    end
  end

  def to_src context={}
    @context = context
    
    if desc.blank?
      "[#{target_href}]"
    else
      "[#{target_href}|#{desc.text_value}]"
    end
  end

  def link_update from, to, context
    @context = context
    
    t = target
    
    target_page = t.is_a?(Page) ? t : t.page
    
    return false if target_page.namespace != from.namespace || target_page.name != from.name
    
    if t.is_a? Page
      @target = to
    else
      t.page.namespace = to.namespace
      t.page.name = to.name
      @target = t
    end
    
    true
  end
  
  def links context={}
    @context = context
    
    [target]
  end
  
  private
  
  def title
    desc.text_value.blank? ? href.to_html(@context).strip : desc.to_html(@context)
  end
  
  def target
    @target || target_for(href.text_value+revision.text_value, @context)
  end
  
  def target_href
    t = target @context
    
    if t.is_a? Attachment
      if t.page.namespace != context[:page].namespace
        "#{t.page.namespace}/#{t.page.name}/#{t.name}"
      elsif t.page.name != context[:page].name
        "#{t.page.name}/#{t.name}"
      else
        t.name
      end
    else
      unless t.namespace == context[:page].namespace
        "#{t.namespace}/#{t.name}"
      else
        t.name
      end
    end
  end

end
