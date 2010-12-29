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
  LOCK_TIME = 1800
  
  class PageError < StandardError; end
  
  include Raki::Helpers::URLHelper
  
  attr_reader :errors
  
  def initialize(params={})
    @namespace = params[:namespace].to_s.strip
    @name = params[:name].to_s.strip
    if params[:revision]
      provider.page_revisions(namespace, name).each do |r|
        if r[:id].to_s == params[:revision].to_s.strip
          @revision = hash_to_revision(r)
          break
        end
      end
    end
    @errors = nil
  end
  
  def namespace
    @new_namespace || @namespace
  end
  
  def namespace=(namespace)
    @new_namespace = namespace.to_s.strip
    reset if renamed?
  end
  
  def name
    @new_name || @name
  end
  
  def name=(name)
    @new_name = name.to_s.strip
    reset if renamed?
  end
  
  def revision
    return nil unless exists?
    @revision ||= head_revision
  end
  
  def exists?
    @exists ||= provider.page_exists?(namespace, name, (@revision ? @revision.id : nil))
  end
  
  def content
    return @content unless exists?
    @content ||= provider.page_contents(namespace, name, (@revision ? @revision.id : nil))
  end
  
  def content=(content)
    @content_changed = self.content != content
    @content = content
  end
  
  def revisions
    return [] unless exists?
    @revisions ||= provider.page_revisions(namespace, name).collect{|r| hash_to_revision(r)}
  end
  
  def head_revision
    return nil unless provider.page_exists?(namespace, name)
    hash_to_revision(provider.page_revisions(namespace, name, :limit => 1).first)
  end
  
  def attachments
    return [] unless exists?
    @attchments ||= provider.attachment_all(namespace, name).collect do |attachment|
      Attachment.new(:namespace => namespace, :page => name, :name => attachment)
    end
  end
  
  def diff(rev_to)
    return nil unless exists?
    to = Page.find(namespace, name, (rev_to.is_a?(Revision) ? rev_to.id : rev_to))
    Diff.create(self, to)
  end
  
  def url(options={})
    if options.is_a?(Symbol) || options.is_a?(String)
      options = {:action => options}
    else
      options = options.symbolize_keys
      options[:revision] = options[:revision].id if options.key?(:revision) && options[:revision].is_a?(Revision)
    end
    options = {:controller => 'page', :action => 'view', :namespace => namespace, :page => name, :revision => (revision ? revision.id : nil)}.merge options
    unless options[:force_revision]
      options.delete :revision if !options[:revision] || head_revision && options[:revision] == head_revision.id
    end
    options.delete :force_revision
    
    opts = {}
    options.each{|k,v| opts[k] = h(v.to_s)}
    
    url_for opts
  end
  
  def render(context={})
    context = context.clone
    context[:page] = self
    parser.parse content, context
  end
  
  def authorized?(user, action='view')
    Raki::Authorizer.authorized_to?(namespace, name, action, user)
  end
  
  def locked?
    current_lock ? true : false
  end
  
  def locked_by
    return nil unless locked?
    Raki::Authenticator.user_for(:username => current_lock.locked_by)
  end
  
  def locked_at
    return nil unless locked?
    current_lock.locked_at
  end
  
  def locked_until
    return nil unless locked?
    current_lock.expires_at
  end
  
  def lock(user)
    unless current_lock
      Lock.create!(
        :page_namespace => namespace,
        :page_name => name,
        :locked_by => user.username,
        :locked_at => Time.new,
        :expires_at => Time.new + LOCK_TIME
      )
      true
    else
      false
    end
  end
  
  def unlock(user)
    return true unless current_lock
    
    if current_lock.locked_by == user.username
      current_lock.destroy
      true
    else
      false
    end
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
    @errors = []
    
    if renamed?
      @errors << I18n.t('page.edit.page_already_exists') if Page.exists?(namespace, name)
      @errors << I18n.t('page.edit.no_permission_to_create') unless authorized?(user, :create)
      return false unless @errors.empty?
      
      if Raki::Provider[@namespace] == Raki::Provider[namespace]
        provider.page_rename(@namespace, @name, namespace, name, user)
      else
        c = Raki::Provider[@namespace].page_contents(@namespace, @name)
        Raki::Provider[namespace].page_save(namespace, name, c, msg, user)
        Raki::Provider[@namespace].page_delete(@namespace, @name, user)
      end
      Thread.new do
        Page.namespaces.each do |ns|
          Page.all(:namespace => ns).each do |page|
            changed, new_content = Raki::Parser[ns].link_update(page.content, "#{@namespace}/#{@name}", "#{namespace}/#{name}")
            next unless changed
            page.content = new_content
            page.save(user, msg)
          end
        end
      end
      @namespace ||= @new_namespace
      @name ||= @new_name
      @new_namespace = nil
      @new_name = nil
    elsif changed?
      @errors << I18n.t('page.edit.no_contents') if content.nil? || content.blank?
      return false unless @errors.empty?
      
      provider.page_save(namespace, name, content, msg, user)
    end
    
    reset
    @exists = true
    @revision = head_revision
    @errors = nil
    true
  rescue => e
    Rails.logger.error(e)
    @errors << I18n.t('test')
    false
  end
  
  def save!(user, msg=nil)
    unless save(user, msg)
      raise PageError
    end
    true
  end
  
  def delete(user, msg=nil)
    @errors = []
    @errors << I18n.t('page.edit.no_permission_to_delete') unless authorized?(user, :delete)
    return false unless @errors.empty?
    
    provider.page_delete(namespace, name, user)
    
    @errors = nil
    @deleted = true
  rescue
    false
  end
  
  def delete!(user, msg=nil)
    unless delete(user, msg)
      raise PageError
    end
    true
  end
  
  def to_s(revision=false)
    if revision
      "#{namespace}/#{name}@#{revision.version}"
    else
      "#{namespace}/#{name}"
    end
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
    Raki::Provider[namespace.to_s.strip.to_sym].page_exists?(namespace.to_s.strip, name.to_s.strip, revision)
  end
  
  def self.find(namespace, name, revision=nil)
    namespace = namespace.to_s.strip if namespace
    name = name.to_s.strip if name
    revision = revision.to_s.strip if revision
    if Raki::Provider[namespace.to_s.strip.to_sym].page_exists?(namespace.to_s.strip, name.to_s.strip, revision)
      Page.new(:namespace => namespace.to_s.strip, :name => name.to_s.strip, :revision => revision)
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
      pages += Raki::Provider[ns].page_all(ns).select do |p|
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
      revisions += Raki::Provider[ns].page_changes(ns, opts).select do |r|
        page ? !page.select{|pf| pf.is_a?(Regexp) ? (r[:page][:name] =~ pf) : (pf.to_s == "#{r[:page][:namespace]}/#{r[:page][:name]}")}.empty? : true
      end.collect do |r|
        hash_to_revision(r)
      end
    end
    
    revisions.sort{|a,b| a <=> b}
  end
  
  def self.namespaces
    namespaces = []
    Raki::Provider.used.values.each do |provider|
      provider.namespaces.each do |namespace|
        namespaces << namespace if Raki::Provider[namespace] == provider
      end
    end
    namespaces
  end
  
  private
  
  def hash_to_revision(rev)
    Revision.new(self, nil, rev[:id], rev[:version], rev[:size], rev[:user], rev[:date], rev[:message], rev[:mode])
  end
  
  def self.hash_to_revision(rev)
    Revision.new(
      Page.new(:namespace => rev[:page][:namespace], :name => rev[:page][:name], :revision => rev[:id]),
      nil, rev[:id], rev[:version], rev[:size], rev[:user], rev[:date], rev[:message], rev[:mode]
    )
  end
  
  def provider
    Raki::Provider[namespace]
  end
  
  def parser
    Raki::Parser[namespace]
  end
  
  def current_lock
    lock = Lock.find_by_page_namespace_and_page_name(namespace, name)
    
    if lock && lock.expired?
      lock.destroy
      lock = nil
    end
    
    lock
  end
  
  def reset
    @deleted = nil
    @exists = nil  
    @revision = nil
    @revisions = nil
    @head_revision = nil
    @attchments = nil
  end

end
