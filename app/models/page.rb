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
  include Raki::Helpers::ParserHelper
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
    @exists ||= page_exists?(namespace, name, (@revision ? @revision.id : nil))
  end
  
  def content
    return @content unless exists?
    @content ||= page_contents(namespace, name, (revision ? revision.id : nil))
  end
  
  def content=(content)
    @content_changed = self.content != content
    @content = content
  end
  
  def revisions
    return [] unless exists?
    @revisions ||= page_revisions(namespace, name)
  end
  
  def head_revision
    return nil unless exists?
    @head_revision ||= page_revisions(namespace, name).first
  end
  
  def attachments
    return [] unless exists?
    @attchments ||= attachment_all(namespace, name).collect do |attachment|
      Attachment.new(:namespace => namespace, :page => name, :name => attachment)
    end
  end
  
  def diff(options={})
    # TODO
  end
  
  def url(options={})
    if options.is_a?(Symbol) || options.is_a?(String)
      options = {:action => options}
    else
      options = options.symbolize_keys
      options[:revision] = options[:revision].id if options.key?(:revision) && options[:revision].is_a?(Revision)
    end
    options = {:controller => 'page', :action => 'view', :namespace => namespace, :page => name, :revision => (revision ? revision.id : nil)}.merge options
    options.delete :revision if head_revision && options[:revision] == head_revision.id
    
    opts = {}
    options.each{|k,v| opts[k] = h(v.to_s)}
    
    url_for opts
  end
  
  def render(context={})
    context = context.clone
    context[:page] = self
    parse namespace, content, context
  end
  
  def authorized?(user, action='view')
    super(namespace, name, action, user)
  end
  
  def locked?
    Raki::LockManager.locked?(self)
  end
  
  def locked_by
    return nil unless locked?
    Raki::LockManager.locked_by(self)
  end
  
  def lock(user)
    Raki::LockManager.lock(self, user)
  end
  
  def unlock(user)
    Raki::LockManager.unlock(self, user)
  end
  
  def renamed?
    (@new_namespace && @namespace != @new_namespace) || (@new_name && @name != @new_name)
  end
  
  def changed?
    @content_changed ? true : false
  end
  
  def deleted?
    @deleted ? true : false
  end
  
  def save(user, msg=nil)
    if renamed?
      page_rename(@namespace, @name, namespace, name, user)
      @namespace = @new_namespace
      @name = @new_name
      @new_namespace = nil
      @new_name = nil
      @revisions = nil
    end
    if changed?
      page_save(namespace, name, content, msg, user)
      @exists = true
    end
    @head_revision = page_revisions(namespace, name).first
    @revision = @head_revision
    @revisions.unshift @head_revision if @revisions
    true
  rescue
    false
  end
  
  def save!(user, msg=nil)
    unless save(user, msg)
      # TODO
    end
    true
  end
  
  def delete(user, msg=nil)
    page_delete(namespace, name, user)
    @deleted = true
  rescue
    false
  end
  
  def delete!(user, msg=nil)
    unless delete(user, msg)
      # TODO
    end
    true
  end
  
  def to_s
    "#{namespace}/#{name}@#{revision.version}"
  end
  
  def <=> b
    if namespace == b.namespace
      if name == b.name
        if revision && b.revision
          revision.date <=> b.revision.date
        elsif revision
          1
        elsif b.revision
          -1
        else
          0
        end
      else
        name <=> b.name
      end
    else
      namespace <=> b.namespace
    end
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
  
  def self.all(options={})
    pages = []
    
    if options[:namespace].nil?
      namespace = namespaces
    elsif options[:namespace].is_a?(Array)
      namespace = options[:namespace]
    else
      namespace = [options[:namespace]]
    end
    
    if options[:page].nil?
      page = nil
    elsif options[:page].is_a?(Array)
      page = options[:page]
    else
      page = [options[:page]]
    end
    
    namespaces.select do |ns|
      namespace ? !namespace.select{|nsf| nsf.is_a?(Regexp) ? (ns =~ nsf) : (nsf.to_s == ns.to_s)}.empty? : true
    end.each do |ns|
      pages += page_all(ns).select do |p|
        page ? !page.select{|pf| pf.is_a?(Regexp) ? (p =~ pf) : (pf.to_s == p.to_s)}.empty? : true
      end.collect{|p| Page.new(:namespace => ns, :name => p)}
    end
    
    pages.sort{|a,b| a <=> b}
  end
  
  def self.changes(options={})
    revisions = []
    
    if options[:namespace].nil?
      namespace = namespaces
    elsif options[:namespace].is_a?(Array)
      namespace = options[:namespace]
    else
      namespace = [options[:namespace]]
    end
    
    if options[:page].nil?
      page = nil
    elsif options[:page].is_a?(Array)
      page = options[:page]
    else
      page = [options[:page]]
    end
    
    opts = options.clone
    opts.delete :namespace
    opts.delete :page
    
    namespaces.select do |ns|
      namespace ? !namespace.select{|nsf| nsf.is_a?(Regexp) ? (ns =~ nsf) : (nsf.to_s == ns.to_s)}.empty? : true
    end.each do |ns|
      revisions += attachment_changes(ns, nil, opts).select do |r|
        page ? !page.select{|pf| pf.is_a?(Regexp) ? (r.page =~ pf) : (pf.to_s == r.page.to_s)}.empty? : true
      end
    end
    
    revisions.sort{|a,b| a <=> b}
  end
  
end
