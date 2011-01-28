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

class RakiSyntax::Node < Treetop::Runtime::SyntaxNode
  
  include ERB::Util
  include Raki::Helpers::I18nHelper
  include RakiSyntax
  
  private

  def target_for link, context
    page = context[:page] || Page.new(:namespace => Raki.frontpage[:namespace], :name => Raki.frontpage[:name])
    
    parts = link.split '/'
    if parts.length == 3
      Attachment.new(:namespace => parts[0], :page => parts[1], :name => parts[2])
    elsif parts.length == 2
      Attachment.find(page.namespace, parts[0], parts[1]) || Page.new(:namespace => parts[0], :name => parts[1])
    elsif parts.length == 1
      Attachment.find(page.namespace, page.name, parts[0]) || Page.new(:namespace => page.namespace, :name => parts[0])
    else
      nil
    end
  rescue => e
    Rails.logger.error e
    nil
  end
  
end


class RakiSyntax::IgnoreNode < RakiSyntax::Node

  def to_html context
    ''
  end

end


class RakiSyntax::EscapedNode < RakiSyntax::Node

  def to_html context
    h text_value[1..-1]
  end

end


class RakiSyntax::LinebreakNode < RakiSyntax::Node

  def to_html context
    '<br/>'
  end

end
