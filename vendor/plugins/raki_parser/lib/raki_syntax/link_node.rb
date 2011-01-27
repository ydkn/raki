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

class RakiSyntax::LinkNode < RakiSyntax::Node

  DANGEROUS_PROTOCOLS = [
      'about', 'wysiwyg', 'data', 'view-source', 'ms-its', 'mhtml',
      'shell', 'lynxexec',  'lynxcgi', 'hcp', 'ms-help', 'help',
      'disk', 'vnd.ms.radio', 'opera', 'res', 'resource',  'chrome',
      'mocha', 'livescript', 'javascript', 'vbscript'
    ]
  SAFE_PROTOCOLS = ['http', 'https', 'ftp', 'mailto', 'sip', 'skype']

  def to_html context
    @context = context
    
    if SAFE_PROTOCOLS.include? protocol_name
      "<a href=\"#{h target}\">#{title}</a>"
    else
      #TODO: no attribute "target" in XHTML 1.1
      "<a target=\"_blank\" href=\"#{h target}\">#{title}</a>"
    end
  end
  
  private
  
  def protocol_name
    href.protocol.to_html(@context).strip.downcase
  end
  
  def target
    href.to_html(@context).strip
  end
  
  def title
    desc.text_value.blank? ? href.to_html(@context).strip : desc.to_html(@context)
  end

end
