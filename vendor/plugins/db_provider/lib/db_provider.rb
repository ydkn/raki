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

  def page_revisions(namespace, name)
    raise PageNotExists unless page_exists?(namespace, name)
    page_id = DBPage.find_by_namespace_and_name(namespace.to_s, name.to_s).id
    revs = []
    DBPageRevision.find_all_by_page_id(page_id, :order => 'revision DESC').each do |revision|
      revs << Revision.new(
          Page.new(:namespace => namespace, :name => name),
          revision.revision,
          revision.revision,
          revision.content.size,
          Raki::Authenticator.user_for(:username => revision.author),
          revision.date,
          revision.message,
          :none
        )
    end
    revs
  end

  def page_save(namespace, name, contents, message, user)
    message = nil if message.empty?
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
    page = DBPage.find_by_namespace_and_name(old_namespace.to_s, old_name.to_s)
    page.namespace = new_namespace.to_s
    page.name = new_name.to_s
    page.save
  end

  def page_delete(namespace, name, user)
    raise PageNotExists unless page_exists?(namespace, name)
    begin
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
    DBPageRevision.all(:joins => "INNER JOIN #{DBPage.table_name} ON #{DBPage.table_name}.id = #{DBPageRevision.table_name}.page_id", :conditions => ["namespace = ?", namespace.to_s], :order => 'date DESC', :limit => limit).each do |revision|
      break if options[:since] && options[:since] <= revision.date
      changes << Revision.new(
          Page.new(:namespace => namespace, :name => name),
          revision.revision,
          revision.revision,
          revision.content.size,
          Raki::Authenticator.user_for(:username => revision.author),
          revision.date,
          revision.message,
          :none
        )
    end
    changes = changes.sort { |a,b| b.revision.date <=> a.revision.date }
    changes
  end
  
  def page_diff(namespace, page, revision_from=nil, revision_to=nil)
    if revision_from.nil?
      revision_from = DBPageRevision.find_all_by_namespace_and_name(namespace.to_s, page.to_s, :order => 'revision DESC', :limit => 2).last.revision
    end
    revision_to = revision_from + 1 if revision_to.nil?
    rev_from = DBPageRevision.find_by_namespace_and_name_and_revision(namespace.to_s, page.to_s, revision_from.to_i)
    rev_to = DBPageRevision.find_by_namespace_and_name_and_revision(namespace.to_s, page.to_s, revision_to.to_i)
    
    diff_lines = []
    # TODO implment diff generation 
    Diff.new(diff_lines)
  rescue
    raise ProviderError.new('Invalid revisions')
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

  def attachment_revisions(namespace, page, name)
    raise AttachmentNotExists unless attachment_exists?(namespace, page, name)
    att_id = DBAttachment.find_by_namespace_and_page_and_name(namespace.to_s, page.to_s, name.to_s).id
    revs = []
    DBAttachmentRevision.find_all_by_attachment_id(att_id, :order => 'revision DESC').each do |revision|
      revs << Revision.new(
          Attachment.new(:namespace => namespace, :page => page, :name => name),
          revision.revision,
          revision.revision,
          revision.content.size,
          Raki::Authenticator.user_for(:username => revision.author),
          revision.date,
          revision.message,
          :none
        )
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
    DBAttachment.find_all_by_namespace_and_page(namespace.to_s).collect{|attachment| attachment.name}
  end

  def attachment_changes(namespace, page=nil, options={})
    changes = []
    limit = options.key?(:limit) ? options[:limit].to_i : 10000
    if page
      revisions = DBAttachmentRevision.all(:joins => "INNER JOIN #{DBAttachment.table_name} ON #{DBAttachment.table_name}.id = #{DBAttachmentRevision.table_name}.attachment_id", :conditions => ["namespace = ? AND page = ?", namespace.to_s, page.to_s], :order => 'date DESC', :limit => limit)
    else
      revisions = DBAttachmentRevision.all(:joins => "INNER JOIN #{DBAttachment.table_name} ON #{DBAttachment.table_name}.id = #{DBAttachmentRevision.table_name}.attachment_id", :conditions => ["namespace = ?", namespace.to_s], :order => 'date DESC', :limit => limit)
    end
    revisions.each do |revision|
      break if options[:since] && options[:since] <= revision.date
      changes << Revision.new(
          Attachment.new(:namespace => namespace, :page => revision.attachment.page, :name => name),
          revision.revision,
          revision.revision,
          revision.content.size,
          Raki::Authenticator.user_for(:username => revision.author),
          revision.date,
          revision.message,
          :none
        )
    end
    changes = changes.sort { |a,b| b.revision.date <=> a.revision.date }
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
