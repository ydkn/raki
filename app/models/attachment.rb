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

require 'mime/types'

class Attachment
  
  class AttachmentError < StandardError; end
  
  include Raki::Helpers::URLHelper
  
  def initialize(params={})
    if params[:namespace] && params[:page]
      @page = Page.new(:namespace => params[:namespace], :name => params[:page])
    end
    @name = params[:name]
    if params[:revision]
      provider.attachment_revisions(@page.namespace, @page.name, @name).each do |r|
        if r[:id].to_s == params[:revision].to_s.strip
          @revision = hash_to_revision(r)
          break
        end
      end
    end
  end
  
  def page
    @page
  end
  
  def name
    @name
  end
  
  def revision
    return nil unless exists?
    @revision ||= head_revision
  end
  
  def exists?
    @exists ||= provider.attachment_exists?(page.namespace, page.name, name, @revision)
  end
  
  def content
    return @content unless exists?
    @content ||= provider.attachment_contents(page.namespace, page.name, name, revision.id)
  end
  
  def content=(content)
    @content = content
  end
  
  def revisions
    return [] unless exists?
    @revisions ||= provider.attachment_revisions(page.namespace, page.name, name).collect{|r| hash_to_revision(r)}
  end
  
  def head_revision
    return nil unless provider.attachment_exists?(page.namespace, page.name, name)
    hash_to_revision(provider.attachment_revisions(page.namespace, page.name, name, :limit => 1).first)
  end
  
  def mime_type
    return nil unless name
    @mime_type ||= MIME::Types.type_for(name).first.content_type
  rescue
    'application/octet-stream'
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
    provider.attachment_save(page.namespace, page.name, name, content, msg, user)
    @revision = head_revision
    true
  end
  
  def save!(user, msg=nil)
    unless save(user, msg)
      raise AttachmentError
    end
    true
  end
  
  def delete(user, msg=nil)
    provider.attachment_delete(page.namespace, page.name, name, user)
  end
  
  def delete!(user, msg=nil)
    unless delete(user, msg)
      raise AttachmentError
    end
    true
  end
  
  def self.exists?(namespace, page, name, revision=nil)
    Raki::Provider[namespace.to_s.strip.to_sym].attachment_exists?(namespace.to_s.strip, page.to_s.strip, name.to_s.strip, revision)
  end
  
  def self.find(namespace, page, name, revision=nil)
    if Raki::Provider[namespace.to_s.strip.to_sym].attachment_exists?(namespace.to_s.strip, page.to_s.strip, name.to_s.strip, revision)
      Attachment.new(:namespace => namespace.to_s.strip, :page => page.to_s.strip, :name => name.to_s.strip, :revision => revision)
    else
      nil
    end
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
    
    if options[:name].nil?
      name = nil
    elsif options[:name].is_a?(Array)
      name = options[:name]
    else
      name = [options[:name]]
    end
    
    opts = options.clone
    opts.delete :namespace
    opts.delete :page
    opts.delete :name
    
    namespaces.select do |ns|
      namespace ? !namespace.select{|nsf| nsf.is_a?(Regexp) ? (ns =~ nsf) : (nsf.to_s == ns.to_s)}.empty? : true
    end.each do |ns|
      revisions += Raki::Provider[ns].attachment_changes(ns, nil, opts).select do |r|
        ret = true
        if page
          ret = !page.select{|pf| pf.is_a?(Regexp) ? (r[:page][:name] =~ pf) : (pf.to_s == "#{r[:page][:namespace]}/#{r[:page][:name]}")}.empty?
        end
        if name && ret
          ret = !name.select{|nf| nf.is_a?(Regexp) ? (r.attachment.name =~ nf) : (nf.to_s == r.attachment.name.to_s)}.empty?
        end
        ret
      end.collect do |r|
        hash_to_revision(r)
      end
    end
    
    revisions.sort{|a,b| a <=> b}
  end
  
  private
  
  def hash_to_revision(rev)
    Revision.new(@page, self, rev[:id], rev[:version], rev[:size], rev[:user], rev[:date], rev[:message], rev[:mode])
  end
  
  def self.hash_to_revision(rev)
    Revision.new(
      Page.new(:namespace => rev[:page][:namespace], :name => rev[:page][:name]),
      Attachment.new(:namespace => rev[:page][:namespace], :page => rev[:page][:name], :name => rev[:attachment]),
      rev[:id], rev[:version], rev[:size], rev[:user], rev[:date], rev[:message], rev[:mode]
    )
  end
  
  def provider
    Raki::Provider[@page.namespace]
  end
  
  def self.namespaces
    Page.namespaces
  end
  
end
