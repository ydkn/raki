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

class Page
  
  extend Raki::Helpers::ProviderHelper
  
  include Raki::Helpers::AuthorizationHelper
  include Raki::Helpers::ProviderHelper
  include Raki::Helpers::URLHelper
  
  def initialize(params={})
    @namespace = params[:namespace]
    @name = params[:name]
    if params[:revision]
      @revision = page_revisions(namespace, name).select{|r| r.id.to_s == params[:revision].to_s}.first
    end
  end
  
  def namespace
    @namespace
  end
  
  def namespace=(namespace)
  end
  
  def name
    @name
  end
  
  def name=(name)
  end
  
  def revision
    @revision ||= page_revisions(namespace, name).first
  end
  
  def exists?
    @exists ||= page_exists?(namespace, name, (revision ? revision.id : nil))
  end
  
  def content
    @content ||= page_contents(namespace, name, (revision ? revision.id : nil)) rescue ''
  end
  
  def content=(content)
    @content = content
  end
  
  def revisions
    page_revisions(namespace, name)
  end
  
  def head
    page_revisions(namespace, name).first
  end
  
  def attachments
    @attchments ||= attachment_all(namespace, name).collect do |attachment|
      Attachment.new(:namespace => namespace, :page => name, :name => attachment)
    end
  end
  
  def url(action='view')
    if revision && revision.id != head.id
      rev = action.to_sym == :view ? revision.id : nil
    else
      rev = nil
    end
    url_for_page(namespace, name, rev, action)
  end
  
  def authorized?(user, action='view')
    super(namespace, name, action, user)
  end
  
  def authorized!(user, action='view')
    super(namespace, name, action, user)
  end
  
  def save(user, msg=nil)
    page_save(namespace, name, content, msg, user)
    @revision = head
    @exists = true
  end
  
  def delete(user, msg=nil)
    page_delete(namespace, name, user)
  end
  
  def self.exists?(namespace, name, revision=nil)
    page_exists?(namespace, name, revision)
  end
  
  def self.find(namespace, name, revision=nil)
    if page_exists?(namespace, name, revision)
      Page.new(:namespace => namespace, :name => name, :revision => revision)
    else
      nil
    end
  end
  
end
