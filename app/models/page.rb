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
  
  attr_reader :errors
  
  def initialize(params={})
    @namespace = params[:namespace]
    @name = params[:name]
    if params[:revision]
      @revision = page_revisions(namespace, name).select{|r| r.id.to_s == params[:revision].to_s}.first
    end
    @errors = []
  end
  
  def namespace
    @new_namespace || @namespace
  end
  
  def namespace=(namespace)
    @new_namespace = namespace
  end
  
  def name
    @new_name || @name
  end
  
  def name=(name)
    @new_name = name
  end
  
  def revision
    return nil unless exists?
    @revision ||= page_revisions(namespace, name).first
  end
  
  def exists?
    @exists ||= page_exists?(namespace, name, (revision ? revision.id : nil))
  end
  
  def content
    return @content unless exists?
    @content ||= page_contents(namespace, name, (revision ? revision.id : nil))
  end
  
  def content=(content)
    @content = content
  end
  
  def revisions
    return [] unless exists?
    @revisions ||= page_revisions(namespace, name)
  end
  
  def head_revision
    @head_revision ||= page_revisions(namespace, name).first
  end
  
  def attachments
    @attchments ||= attachment_all(namespace, name).collect do |attachment|
      Attachment.new(:namespace => namespace, :page => name, :name => attachment)
    end
  end
  
  def url(options={})
    if options.is_a?(Symbol)
      options = {:action => options}
    else
      options = options.symbolize_keys
    end
    options = {:controller => 'page', :action => 'view', :namespace => h(namespace.to_s), :page => h(name.to_s), :revision => (revision ? revision.id : nil)}.merge options
    options.delete :revision if head_revision && options[:revision] == head_revision.id
    url_for options
  end
  
  def authorized?(user, action='view')
    super(namespace, name, action, user)
  end
  
  def changed?
    @namespace != @new_namespace || @name != @new_name
  end
  
  def save(user, msg=nil)
    page_save(namespace, name, content, msg, user)
    @head_revision = page_revisions(namespace, name).first
    @revision = @head_revision
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
