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
  
  class LimitReached < StandardError
  end
  
  include Cacheable

  def initialize(namespace, params)
    raise ProviderError.new("Parameter 'path' not specified") unless params.key?('path')
    begin
      Grit::Git.git_timeout = 10
      Grit::Git.git_max_size = 26214400
      @branch = params.key?('branch') ? params['branch'] : 'master'
      refresh = params.key?('refresh') ? params['refresh'].to_i : 600
      
      FileUtils.rm_rf("#{Rails.root}/tmp/git-repo_#{namespace}")
      @repo = Grit::Repo.clone(params['path'], "#{Rails.root}/tmp/git-repo_#{namespace}")
      @repo.checkout(@branch)
      
      Thread.new do
        while true do
          sleep refresh
          begin
            pull
          rescue => e
          end
        end
      end
    rescue => e
      raise ProviderError.new("Failed to initialize GIT repository: #{e.to_s}")
    end
  end

  def page_exists?(namespace, name, revision=nil)
    logger.debug("Checking if page exists: #{{:namespace => namespace, :name => name, :revision => revision}.inspect}")
    exists?("#{namespace.to_s}/#{name.to_s}", revision)
  end

  def page_contents(namespace, name, revision=nil)
    logger.debug("Fetching contents of page: #{{:namespace => namespace, :name => name, :revision => revision}.inspect}")
    contents("#{namespace.to_s}/#{name.to_s}", revision)
  end

  def page_revisions(namespace, name)
    logger.debug("Fetching revisions for page: #{{:namespace => namespace, :name => name}.inspect}")
    revisions("#{namespace.to_s}/#{name.to_s}")
  end

  def page_save(namespace, name, contents, message, user)
    logger.debug("Saving page: #{{:namespace => namespace, :name => name, :contents => contents, :message => message, :user => user}.inspect}")
    save("#{namespace.to_s}/#{name.to_s}", contents, message, user)
  end

  def page_rename(old_namespace, old_name, new_namespace, new_name, user)
    logger.debug("Renaming page: #{{:old_namespace => old_namespace, :old_page => old_name, :new_namespace => new_namespace, :new_page => new_name, :user => user}.inspect}")
    msg = old_namespace.to_s == new_namespace.to_s ? "#{old_name.to_s} ==> #{new_name.to_s}" : "#{old_namespace.to_s}/#{old_name.to_s} ==> #{new_namespace.to_s}/#{new_name.to_s}"
    rename("#{old_namespace.to_s}/#{old_name.to_s}", "#{new_namespace.to_s}/#{new_name.to_s}", msg, user)
  end

  def page_delete(namespace, name, user)
    logger.debug("Deleting page: #{{:namespace => namespace, :page => name, :user => user}.inspect}")
    delete("#{namespace.to_s}/#{name.to_s}", "#{name.to_s} ==> /dev/null", user)
  end

  def page_all(namespace)
    logger.debug("Fetching all pages")
    all(namespace.to_s)
  end

  def page_changes(namespace, options={})
    logger.debug("Fetching all page changes: #{{:namespace => namespace, :options => options}.inspect}")
    changes(namespace.to_s, namespace.to_s, options)
  end
  
  def page_diff(namespace, page, revision_from=nil, revision_to=nil)
    logger.debug("Fetching diff: #{{:namespace => namespace, :page => page, :revision_from => revision_from, :revision_to => revision_to}.inspect}")
    diff("#{namespace.to_s}/#{page.to_s}", revision_from, revision_to)
  end

  def attachment_exists?(namespace, page, name, revision=nil)
    logger.debug("Checking if page attachment exists: #{{:namespace => namespace, :page => page, :name => name, :revision => revision}.inspect}")
    exists?("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", revision)
  end

  def attachment_contents(namespace, page, name, revision=nil)
    logger.debug("Fetching contents of page attachment: #{{:namespace => namespace, :page => page, :name => name, :revision => revision}.inspect}")
    contents("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", revision)
  end

  def attachment_revisions(namespace, page, name)
    logger.debug("Fetching revisions for page attachment: #{{:namespace => namespace, :page => page, :name => name}.inspect}")
    revisions("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}")
  end

  def attachment_save(namespace, page, name, contents, message, user)
    logger.debug("Saving page attachment: #{{:namespace => namespace, :page => page, :name => name, :contents => contents, :message => message, :user => user}.inspect}")
    save("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", contents, message, user)
  end

  def attachment_delete(namespace, page, name, user)
    logger.debug("Deleting page attachment: #{{:namespace => namespace, :page => page, :name => name, :user => user}.inspect}")
    delete("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", "#{page.to_s}/#{name.to_s} ==> /dev/null", user)
  end

  def attachment_all(namespace, page)
    logger.debug("Fetching all page attachments: #{{:namespace => namespace, :page => page}.inspect}")
    all("#{namespace.to_s}/#{page.to_s}_att")
  end

  def attachment_changes(namespace, page=nil, options={})
    logger.debug("Fetching all page attachment changes: #{{:namespace => namespace, :page => page, :options => options}.inspect}")
    if page.nil?
      changes = []
      page_all(namespace).each do |page|
        changes += changes(namespace, "#{namespace.to_s}/#{page.to_s}_att", options, page)
      end
      changes.sort { |a,b| a.revision.date <=> b.revision.date }
    else
      changes(namespace, "#{namespace.to_s}/#{page.to_s}_att", options, page)
    end
  end
  
  def namespaces
    namespaces = []
    @repo.log.each do |commit|
      commit.tree.trees.each do |tree|
        namespaces << tree.name
      end
    end
    namespaces = namespaces.uniq
    namespaces.delete(nil)
    namespaces
  end
  cache :namespaces

  private

  def check_obj(obj)
    raise InvalidName if obj.nil? || obj.empty?
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
    raise PageNotExists
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
    flush(:namespaces)
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
    flush(:exists?)
    flush(:contents, old_obj, nil)
    flush(:contents, new_obj, nil)
    flush(:revisions, old_obj)
    flush(:revisions, new_obj)
    flush(:changes)
    flush(:namespaces)
  end

  def delete(obj, message, user)
    check_obj(obj)
    check_user(user)
    obj = normalize(obj)
    raise PageNotExists unless exists?(obj)
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
    flush(:namespaces)
  end

  def revisions(obj)
    check_obj(obj)
    obj = normalize(obj)
    raise PageNotExists unless exists? obj
    revs = []
    parts = obj.split('/')
    @repo.log(@branch, obj).each do |commit|
      deleted = false
      commit.diffs.each do |diff|
        next unless diff.a_path == obj
        deleted = diff.deleted_file
      end
      revs << Revision.new(
          ((parts.length == 2) ? Page.new(:namespace => parts[0], :name => parts[1]) : Attachment.new(:namespace => parts[0], :page => parts[1], :name => parts[2])),
          commit.sha,
          commit.id_abbrev.upcase,
          (deleted ? -1 : size(obj, commit.sha)),
          Raki::Authenticator.user_for(:username => commit.author.name, :email => commit.author.email),
          commit.authored_date,
          commit.message,
          deleted ? :deleted : nil
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
  private :all

  def changes(namespace, dir, options={}, page=nil)
    check_obj(dir)
    changes = []
    begin
      @repo.log(@branch, dir).each do |commit|
        break if options[:since] && options[:since] <= commit.authored_date
        commit.diffs.each do |diff|
          if page
            changes << Revision.new(
                Attachment.find(namespace, page, normalize(File.basename(diff.a_path)), commit.sha),
                commit.sha,
                commit.id_abbrev.upcase,
                (diff.deleted_file ? -1 : size(diff.a_path, commit.sha)),
                Raki::Authenticator.user_for(:username => commit.author.name, :email => commit.author.email),
                commit.authored_date,
                commit.message,
                diff.deleted_file ? :deleted : nil
              )
          else
            changes << Revision.new(
                Page.find(namespace, normalize(File.basename(diff.a_path)), commit.sha),
                commit.sha,
                commit.id_abbrev.upcase,
                (diff.deleted_file ? -1 : size(diff.a_path, commit.sha)),
                Raki::Authenticator.user_for(:username => commit.author.name, :email => commit.author.email),
                commit.authored_date,
                commit.message,
                diff.deleted_file ? :deleted : nil
              )
          end
          raise LimitReached if options[:limit] && changes.length >= options[:limit]
        end
      end
    rescue LimitReached
    end
    changes = changes.sort { |a,b| b.date <=> a.date }
    changes
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
  rescue
    raise ProviderError.new('Invalid revisions')
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
    @repo.push('origin', @branch)
  end
  
  def pull
    @repo.pull('origin', @branch)
  end

  def logger
    Rails.logger
  end
  
end
