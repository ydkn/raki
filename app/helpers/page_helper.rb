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

module PageHelper
  
  def url_for_page namespace, page, revision=nil
    options = {:controller => 'page', :action => 'view', :namespace => h(namespace), :page => h(page)}
    options[:revision] = h(revision) if revision
    url_for options
  end
  
  def context
    @context
  end

  def insert_page page
    return unless page
    if page.authorized?(User.current, :view) && page.exists?
      page.render context
    end
  end
  
  def format_diff diff
    ""
  end
  
  def toolbar_item options
    options = options.clone
    opts = {}
    
    opts[:title] = options[:title] || t("toolbar.#{options[:id]}")
    options.delete :title
    
    opts[:id] = "toolbar-#{options[:id]}"
    id = options.delete :id
    
    image = options[:image] || "toolbar/#{id}.png"
    options.delete :image
    
    options.each do |key, value|
      opts["data-#{key}"] = value
    end
    
    opts[:class] = 'item'
    
    link_to image_tag(image), '#', opts
  end

end
