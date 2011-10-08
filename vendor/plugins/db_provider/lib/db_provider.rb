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

class DBProvider < Raki::AbstractProvider

  def initialize(namespace, params)
    if params['connection']
      ActiveRecord::Base.configurations['raki_db_provider'] = params['connection'].symbolize_keys
    else
      ActiveRecord::Base.configurations['raki_db_provider'] = ActiveRecord::Base.configurations[Rails.env]
    end
  end

  def page_exists?(namespace, name, revision=nil)
    return false if DBPage.find_by_namespace_and_name(namespace.to_s, name.to_s).nil?
    if revision
      page_id = DBPage.find_by_namespace_and_name(namespace.to_s, name.to_s).id
      return false if DBPageRevision.find_by_page_id_and_revision(page_id, revision.to_i).nil?
    end
    true
  end

  def page_contents(namespace, name, revision=nil)
    raise PageNotExists unless page_exists?(namespace, name, revision)
    page_id = DBPage.find_by_namespace_and_name(namespace.to_s, name.to_s).id
    if revision
      return DBPageRevision.find_by_page_id_and_revision(page_id, revision.to_i).content
    else
      return DBPageRevision.find_by_page_id(page_id, :order => 'revision DESC', :limit => 1).content
    end
    true
  end

  def page_revisions(namespace, name, options={})
    raise PageNotExists unless page_exists?(namespace, name)
    page_id = DBPage.find_by_namespace_and_name(namespace.to_s, name.to_s).id
    revs = []
    DBPageRevision.find_all_by_page_id(page_id, :order => 'revision DESC', :limit => options[:limit]).each do |revision|
      break if options[:since] && options[:since] <= revision.date
      mode = case revision.revision
        when 1
          :created
        else
          :modified
      end
      revs << {
        :id => revision.revision,
        :version => revision.revision,
        :date => revision.date,
        :message => revision.message,
        :user => Raki::Authenticator.user_for(:username => revision.author),
        :mode => mode,
        :size => revision.content.size,
        :type => :page
      }
    end
    revs
  end

  def page_save(namespace, name, contents, message, user)
    message = nil if message && message.strip.blank?
    page = DBPage.find_by_namespace_and_name(namespace.to_s, name.to_s)
    page = DBPage.create!(:namespace => namespace.to_s, :name => name.to_s) unless page
    revision = DBPageRevision.find_by_page_id(page.id, :order => 'revision DESC', :limit => 1)
    if revision.nil?
      revision = 1
    else
      revision = revision.revision + 1
    end
    DBPageRevision.create!(:page_id => page.id, :revision => revision, :author => user.username, :date => Time.new, :message => message, :content => contents)
    true
  rescue => e
    logger.error(e)
    false
  end

  def page_rename(old_namespace, old_name, new_namespace, new_name, user)
    raise ProviderError.new 'Target page already exists' if page_exists?(new_namespace, new_name)
    
    DBAttachment.find_all_by_namespace_and_page(old_namespace.to_s, old_name.to_s).each do |attachment|
      attachment.namespace = new_namespace.to_s
      attachment.page = new_name.to_s
      attachment.save
    end
    
    page = DBPage.find_by_namespace_and_name(old_namespace.to_s, old_name.to_s)
    page.namespace = new_namespace.to_s
    page.name = new_name.to_s
    page.save
  end

  def page_delete(namespace, name, user)
    raise PageNotExists unless page_exists?(namespace, name)
    begin
      DBAttachment.find_all_by_namespace_and_page(namespace.to_s, name.to_s).each do |attachment|
        attachment.attachment_revisions.each do |attachment_revision|
          attachment_revision.destroy
        end
        attachment.destroy
      end
      DBPageRevision.all(:joins => "INNER JOIN #{DBPage.table_name} ON #{DBPage.table_name}.id = #{DBPageRevision.table_name}.page_id", :conditions => ["namespace = ? AND name = ?", namespace.to_s, name.to_s]).each do |revision|
        revision.destroy
      end
      DBPage.find_by_namespace_and_name(namespace.to_s, name.to_s).destroy
      true
    rescue => e
      logger.error(e)
      false
    end
  end

  def page_all(namespace)
    DBPage.find_all_by_namespace(namespace.to_s).collect{|page| page.name}
  end

  def page_changes(namespace, options={})
    changes = []
    limit = options.key?(:limit) ? options[:limit].to_i : 10000
    if options[:since]
      condition = ["namespace = ? AND date >= ?", namespace.to_s, options[:since].to_time]
    else
      condition = ["namespace = ?", namespace.to_s]
    end
    DBPageRevision.all(:joins => "INNER JOIN #{DBPage.table_name} ON #{DBPage.table_name}.id = #{DBPageRevision.table_name}.page_id", :conditions => condition, :order => 'date DESC', :limit => limit).each do |revision|
      mode = case revision.revision
        when 1
          :created
        else
          :modified
        end
      changes << {
        :id => revision.revision,
        :version => revision.revision,
        :date => revision.date,
        :message => revision.message,
        :user => Raki::Authenticator.user_for(:username => revision.author),
        :mode => mode,
        :size => revision.content.size,
        :type => :page,
        :page => {:namespace => revision.page.namespace, :name => revision.page.name}
      }
    end
    changes
  end

  def attachment_exists?(namespace, page, name, revision=nil)
    return false if DBAttachment.find_by_namespace_and_page_and_name(namespace.to_s, page.to_s, name.to_s).nil?
    if revision
      att_id = DBAttachment.find_by_namespace_and_page_and_name(namespace.to_s, page.to_s, name.to_s).id
      return false if DBAttachmentRevision.find_by_attachment_id_and_revision(att_id, revision.to_i).nil?
    end
    true
  end

  def attachment_contents(namespace, page, name, revision=nil)
    raise AttachmentNotExists unless attachment_exists?(namespace, page, name, revision)
    att_id = DBAttachment.find_by_namespace_and_page_and_name(namespace.to_s, page.to_s, name.to_s).id
    if revision
      return DBAttachmentRevision.find_by_attachment_id_and_revision(att_id, revision.to_i).content
    else
      return DBAttachmentRevision.find_by_attachment_id(att_id, :order => 'revision DESC', :limit => 1).content
    end
    true
  end

  def attachment_revisions(namespace, page, name, options={})
    raise AttachmentNotExists unless attachment_exists?(namespace, page, name)
    att_id = DBAttachment.find_by_namespace_and_page_and_name(namespace.to_s, page.to_s, name.to_s).id
    revs = []
    DBAttachmentRevision.find_all_by_attachment_id(att_id, :order => 'revision DESC', :limit => options[:limit]).each do |revision|
      break if options[:since] && options[:since] <= revision.date
      mode = case revision.revision
        when 1
          :created
        else
          :modified
      end
      revs << {
        :id => revision.revision,
        :version => revision.revision,
        :date => revision.date,
        :message => revision.message,
        :user => Raki::Authenticator.user_for(:username => revision.author),
        :mode => mode,
        :size => revision.content.size,
        :type => :attachment
      }
    end
    revs
  end

  def attachment_save(namespace, page, name, contents, message, user)
    message = nil if message.empty?
    att = DBAttachment.find_by_namespace_and_page_and_name(namespace.to_s, page.to_s, name.to_s)
    att = DBAttachment.create!(:namespace => namespace.to_s, :page => page.to_s, :name => name.to_s) unless att
    revision = DBAttachmentRevision.find_by_attachment_id(att.id, :order => 'revision DESC', :limit => 1)
    if revision.nil?
      revision = 1
    else
      revision = revision.revision + 1
    end
    DBAttachmentRevision.create!(:attachment_id => att.id, :revision => revision, :author => user.username, :date => Time.new, :message => message, :content => contents)
    true
  rescue => e
    logger.error(e)
    false
  end

  def attachment_delete(namespace, page, name, user)
    raise AttachmentNotExists unless attachment_exists?(namespace, page, name)
    begin
      DBAttachmentRevision.all(:joins => "INNER JOIN #{DBAttachment.table_name} ON #{DBAttachment.table_name}.id = #{DBAttachmentRevision.table_name}.attachment_id", :conditions => ["namespace = ? AND page = ? AND name = ?", namespace.to_s, page.to_s, name.to_s]).each do |revision|
        revision.destroy
      end
      DBAttachment.find_by_namespace_and_page_and_name(namespace.to_s, page.to_s, name.to_s).destroy
      true
    rescue => e
      logger.error(e)
      false
    end
  end

  def attachment_all(namespace, page)
    DBAttachment.find_all_by_namespace_and_page(namespace.to_s, page.to_s).collect{|attachment| attachment.name}
  end

  def attachment_changes(namespace, page=nil, options={})
    changes = []
    limit = options.key?(:limit) ? options[:limit].to_i : 10000
    if page
      if options[:since]
        condition = ["namespace = ? AND page = ? AND date >= ?", namespace.to_s, page.to_s, options[:since].to_time]
      else
        condition = ["namespace = ? AND page = ?", namespace.to_s, page.to_s]
      end
      revisions = DBAttachmentRevision.all(:joins => "INNER JOIN #{DBAttachment.table_name} ON #{DBAttachment.table_name}.id = #{DBAttachmentRevision.table_name}.attachment_id", :conditions => condition, :order => 'date DESC', :limit => limit)
    else
      if options[:since]
        condition = ["namespace = ? AND date >= ?", namespace.to_s, options[:since].to_time]
      else
        condition = ["namespace = ?", namespace.to_s]
      end
      revisions = DBAttachmentRevision.all(:joins => "INNER JOIN #{DBAttachment.table_name} ON #{DBAttachment.table_name}.id = #{DBAttachmentRevision.table_name}.attachment_id", :conditions => condition, :order => 'date DESC', :limit => limit)
    end
    revisions.each do |revision|
      mode = case revision.revision
        when 1
          :created
        else
          :modified
        end
      changes << {
        :id => revision.revision,
        :version => revision.revision,
        :date => revision.date,
        :message => revision.message,
        :user => Raki::Authenticator.user_for(:username => revision.author),
        :mode => mode,
        :size => revision.content.size,
        :type => :attachment,
        :page => {:namespace => revision.attachment.namespace, :name => revision.attachment.page},
        :attachment => revision.attachment.name
      }
    end
    changes
  end
  
  def namespaces
    DBPage.all.collect{|page| page.namespace}.uniq
  end
  
  private

  def logger
    Rails.logger
  end
  
end
