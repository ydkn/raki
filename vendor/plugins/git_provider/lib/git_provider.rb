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

require 'rubygems'
require 'grit'
require 'unicode'

class GitProvider < Raki::AbstractProvider
  
  include Cacheable

  def initialize(params)
    raise ProviderError.new("Parameter 'path' not specified") unless params.key?('path')
    begin
      @branch = params.key?('branch') ? params['branch'] : 'master'
      refresh = params.key?('refresh') ? params['refresh'].to_i : 600
      
      FileUtils.rm_rf("#{Rails.root}/tmp/git-repo")
      @repo = Grit::Repo.clone(params['path'], "#{Rails.root}/tmp/git-repo")
      @repo.checkout(@branch)
      
      Thread.new do
        while true do
          sleep refresh
          pull
        end
      end
    rescue => e
      raise ProviderError.new("Failed to initialize GIT repository: #{e.to_s}")
    end
  end

  def page_exists?(type, name, revision=nil)
    logger.debug("Checking if page exists: #{{:type => type, :name => name, :revision => revision}.inspect}")
    exists?("#{type.to_s}/#{name.to_s}", revision)
  end

  def page_contents(type, name, revision=nil)
    logger.debug("Fetching contents of page: #{{:type => type, :name => name, :revision => revision}.inspect}")
    contents("#{type.to_s}/#{name.to_s}", revision)
  end

  def page_revisions(type, name)
    logger.debug("Fetching revisions for page: #{{:type => type, :name => name}.inspect}")
    revisions("#{type.to_s}/#{name.to_s}")
  end

  def page_save(type, name, contents, message, user)
    logger.debug("Saving page: #{{:type => type, :name => name, :contents => contents, :message => message, :user => user}.inspect}")
    save("#{type.to_s}/#{name.to_s}", contents, message, user)
  end

  def page_rename(old_type, old_name, new_type, new_name, user)
    logger.debug("Renaming page: #{{:old_type => old_type, :old_page => old_name, :new_type => new_type, :new_page => new_name, :user => user}.inspect}")
    msg = old_type.to_s == new_type.to_s ? "#{old_name.to_s} ==> #{new_name.to_s}" : "#{old_type.to_s}/#{old_name.to_s} ==> #{new_type.to_s}/#{new_name.to_s}"
    rename("#{old_type.to_s}/#{old_name.to_s}", "#{new_type.to_s}/#{new_name.to_s}", msg, user)
  end

  def page_delete(type, name, user)
    logger.debug("Deleting page: #{{:type => type, :page => name, :user => user}.inspect}")
    delete("#{type.to_s}/#{name.to_s}", "#{name.to_s} ==> /dev/null", user)
  end

  def page_all(type)
    logger.debug("Fetching all pages")
    all(type.to_s)
  end

  def page_changes(type, amount=nil)
    logger.debug("Fetching all page changes: #{{:type => type, :limit => amount}.inspect}")
    changes(type.to_s, type.to_s, amount)
  end
  
  def page_diff(type, page, revision_from=nil, revision_to=nil)
    logger.debug("Fetching diff: #{{:type => type, :page => page, :revision_from => revision_from, :revision_to => revision_to}.inspect}")
    diff("#{type.to_s}/#{page.to_s}", revision_from, revision_to)
  end

  def attachment_exists?(type, page, name, revision=nil)
    logger.debug("Checking if page attachment exists: #{{:type => type, :page => page, :name => name, :revision => revision}.inspect}")
    exists?("#{type.to_s}/#{page.to_s}_att/#{name.to_s}", revision)
  end

  def attachment_contents(type, page, name, revision=nil)
    logger.debug("Fetching contents of page attachment: #{{:type => type, :page => page, :name => name, :revision => revision}.inspect}")
    contents("#{type.to_s}/#{page.to_s}_att/#{name.to_s}", revision)
  end

  def attachment_revisions(type, page, name)
    logger.debug("Fetching revisions for page attachment: #{{:type => type, :page => page, :name => name}.inspect}")
    revisions("#{type.to_s}/#{page.to_s}_att/#{name.to_s}")
  end

  def attachment_save(type, page, name, contents, message, user)
    logger.debug("Saving page attachment: #{{:type => type, :page => page, :name => name, :contents => contents, :message => message, :user => user}.inspect}")
    save("#{type.to_s}/#{page.to_s}_att/#{name.to_s}", contents, message, user)
  end

  def attachment_delete(type, page, name, user)
    logger.debug("Deleting page attachment: #{{:type => type, :page => page, :name => name, :user => user}.inspect}")
    delete("#{type.to_s}/#{page.to_s}_att/#{name.to_s}", "#{page.to_s}/#{name.to_s} ==> /dev/null", user)
  end

  def attachment_all(type, page)
    logger.debug("Fetching all page attachments: #{{:type => type, :page => page}.inspect}")
    all("#{type.to_s}/#{page.to_s}_att")
  end

  def attachment_changes(type, page=nil, amount=nil)
    logger.debug("Fetching all page attachment changes: #{{:type => type, :page => page, :limit => amount}.inspect}")
    if page.nil?
      changes = []
      page_all(type).each do |page|
        changes += changes(type, "#{type.to_s}/#{page.to_s}_att", amount, page)
      end
      changes.sort { |a,b| a.revision.date <=> b.revision.date }
    else
      changes(type, "#{type.to_s}/#{page.to_s}_att", amount, page)
    end
  end
  
  def types
    types = []
    @repo.log.each do |commit|
      commit.tree.trees.each do |tree|
        types << tree.name
      end
    end
    types = types.uniq
    types.delete(nil)
    types
  end
  cache :types

  private

  def check_obj(obj)
    raise ProviderError.new 'Invalid filename' if obj.nil? || obj.empty?
  end

  def check_user(user)
    raise ProviderError.new 'Invalid user' if user.nil? || !user.is_a?(User)
  end

  def check_contents(contents)
    raise ProviderError.new 'Invalid content' if contents.nil?
  end

  def exists?(obj, revision=nil)
    check_obj(obj)
    obj = normalize(obj)
    revision = 'HEAD' if revision.nil?
    begin
      path, file = split_object(obj)
      @repo.tree(revision, path).blobs.each do |blob|
        return true if blob.name == obj
      end
    rescue => e
    end
    false
  end
  cache :exists?

  def contents(obj, revision=nil)
    check_obj(obj)
    obj = normalize(obj)
    revision = 'HEAD' if revision.nil?
    path, file = split_object(obj)
    begin
      @repo.tree(revision, path).blobs.each do |blob|
        return blob.data if blob.name == obj
      end
    rescue => e
    end
    raise ProviderError.new("Object '#{obj}@#{revision}' does not exist!")
  end
  cache :contents

  def save(obj, contents, message, user)
    check_obj(obj)
    check_contents(contents)
    check_user(user)
    obj = normalize(obj)
    message = '-' if message.nil? || message.empty?
    FileUtils.mkdir_p(path("#{@repo.working_dir}/#{obj}"))
    File.open("#{@repo.working_dir}/#{obj}", 'w') do |f|
      f.write(contents)
    end
    @repo.add(obj)
    @repo.commit_index(
        message,
        :author => format_user(user)
    )
    push
    flush(:exists?, obj, nil)
    flush(:contents, obj, nil)
    flush(:revisions, obj)
    flush(:changes)
    flush(:types)
  end

  def rename(old_obj, new_obj, message, user)
    check_obj(old_obj)
    check_obj(new_obj)
    check_user(user)
    old_obj = normalize(old_obj)
    new_obj = normalize(new_obj)
    raise ProviderError.new('Target exists') if exists?(new_obj)
    message = '-' if message.nil? || message.empty?
    FileUtils.mkdir_p(path("#{@repo.working_dir}/#{new_obj}"))
    File.open("#{@repo.working_dir}/#{new_obj}", 'w') do |f|
      f.write(contents(old_obj))
    end
    @repo.remove(old_obj)
    @repo.add(new_obj)
    @repo.commit_index(
        message,
        :author => format_user(user)
    )
    push
    flush(:exists?, old_obj, nil)
    flush(:exists?, new_obj, nil)
    flush(:contents, old_obj, nil)
    flush(:contents, new_obj, nil)
    flush(:revisions, old_obj)
    flush(:revisions, new_obj)
    flush(:changes)
    flush(:types)
  end

  def delete(obj, message, user)
    check_obj(obj)
    check_user(user)
    obj = normalize(obj)
    raise ProviderError.new('Object don\'t exists') unless exists?(obj)
    message = '-' if message.nil? || message.empty?
    @repo.remove(obj)
    @repo.commit_index(
        message,
        :author => format_user(user)
    )
    push
    flush(:exists?, obj, nil)
    flush(:contents, obj, nil)
    flush(:revisions, obj)
    flush(:changes)
    flush(:types)
  end

  def revisions(obj)
    check_obj(obj)
    obj = normalize(obj)
    revs = []
    @repo.log(@branch, obj).each do |commit|
      deleted = false
      commit.diffs.each do |diff|
        next unless diff.a_path == obj
        deleted = diff.deleted_file
      end
      revs << Revision.new(
          commit.sha,
          commit.id_abbrev.upcase,
          (deleted ? -1 : size(obj, commit.sha)),
          Raki::Authenticator.user_for(:username => commit.author.name, :email => commit.author.email),
          commit.authored_date,
          commit.message,
          deleted
        )
    end
    revs
  end
  cache :revisions

  def all(dir, revision=nil)
    check_obj(dir)
    revision = 'HEAD' if revision.nil?
    files = []
    begin
      @repo.tree(revision, "#{dir}/").blobs.each do |blob|
        files << normalize(file(blob.name))
      end
    rescue => e
    end
    files.sort { |a,b| a <=> b }
  end
  cache :all

  def changes(type, dir, amount=0, page=nil)
    check_obj(dir)
    changes = []
    all(dir).each do |obj|
      revisions("#{dir}/#{obj}").each do |revision|
        if page.nil?
          changes << Change.new(type, normalize(obj), revision)
        else
          changes << Change.new(type, normalize(page), revision, normalize(obj))
        end
      end
    end
    changes = changes.sort { |a,b| b.revision.date <=> a.revision.date }
    if amount.nil?
      changes
    else
      changes[0..(amount-1)]
    end
  end
  cache :changes
  
  def diff(obj, revision_from=nil, revision_to=nil)
    check_obj(obj)
    obj = normalize(obj)
    revisions = revisions(obj)
    revision_from = revisions[revisions.length-2].id if revision_from.nil?
    if revision_to.nil?
      rev_from = nil
      revisions.each do |rev|
        rev_from = rev if rev.id == revision_from
      end
      revision_to = revisions[revisions.index(rev_from)-1].id
    end
    diff_lines = []
    @repo.diff(revision_to, revision_from, obj).each do |diff|
      diff_lines += diff.diff.split("\n")
    end
    Diff.new(diff_lines)
  end
  cache :diff
  
  def size(obj, revision)
    obj = normalize(obj)
    path, file = split_object(obj)
    @repo.tree(revision, path).blobs.each do |blob|
      return blob.size if blob.name == obj
    end
    -1
  end
  cache :size, :ttl => 3600
  
  def split_object(obj)
    return obj.gsub(/[^\/]+$/, ''), obj.gsub(/^(.*\/)*/, '')
  end
  
  def path(obj)
    obj.gsub(/[^\/]+$/, '')
  end
  
  def file(obj)
    obj.gsub(/^(.*\/)*/, '')
  end
  
  def normalize(str)
    str = Unicode.normalize_KD(str)
    new_str = ""
    str.each_byte do |c|
      new_str += c.chr if c < 128
    end
    new_str
  end
  cache :normalize, :ttl => 86400
  
  def format_user(user)
    if user.email.nil?
      "#{user.username} <#{user.username}@#{Raki.app_name.underscore}>"
    else
      "#{user.username} <#{user.email}>"
    end
  end
  
  def push
    @repo.push('origin')
  end
  
  def pull
    @repo.pull('origin')
  end

  def logger
    Rails.logger
  end
  
end
