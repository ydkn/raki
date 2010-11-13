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

class Attachment
  
  extend Raki::Helpers::ProviderHelper
  
  include Raki::Helpers::ProviderHelper
  include Raki::Helpers::URLHelper
  
  def initialize(params={})
    if params[:namespace] && params[:page]
      @page = Page.find(params[:namespace], params[:page])
    end
    @name = params[:name]
    if params[:revision]
      @revision = attachment_revisions(namespace, params[:page], params[:name]).select{|r| r.id.to_s == params[:revision].to_s}.first
    end
  end
  
  def page
    @page
  end
  
  def name
    @name
  end
  
  def name=(name)
  end
  
  def revision
    @revision ||= attachment_revisions(page.namespace, page.name, name).first
  end
  
  def exists?
    @exists ||= attachment_exists?(page.namespace, page.name, name, revision.id)
  end
  
  def content
    @content ||= attachment_contents(page.namespace, page.name, name, revision.id)
  end
  
  def content=(content)
    @content = content
  end
  
  def revisions
    attachment_revisions(page.namespace, page.name, name)
  end
  
  def head_revision
    attachment_revisions(page.namespace, page.name, name).first
  end
  
  def url(options={})
    if options.is_a?(Symbol)
      options = {:action => options}
    else
      options = options.symbolize_keys
    end
    options = {:controller => 'page', :action => 'attachment', :namespace => page.namespace, :page => page.name, :attachment => name, :revision => (revision ? revision.id : nil)}.merge options
    options.delete :revision if head_revision && options[:revision] == head_revision.id
    
    opts = {}
    options.each{|k,v| opts[k] = h(v.to_s)}
    
    url_for opts
  end
  
  def save(user, msg=nil)
    attachment_save(page.namespace, page.name, name, content, msg, user)
    @revision = head
    true
  end
  
  def delete(user, msg=nil)
    attachment_delete(page.namespace, page.name, name, user)
  end
  
  def self.exists?(namespace, page, name, revision=nil)
    attachment_exists?(namespace, page, name, revision)
  end
  
  def self.find(namespace, page, name, revision=nil)
    if attachment_exists?(namespace, page, name, revision)
      Attachment.new(:namespace => namespace, :page => page, :name => name, :revision => revision)
    else
      nil
    end
  end
  
end
