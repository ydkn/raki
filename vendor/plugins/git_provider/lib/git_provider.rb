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
require 'unicode'
require 'git_repo'
require 'digest/md5'

class GitProvider < Raki::AbstractProvider
  
  include Cacheable

  def initialize(namespace, params)
    raise ProviderError.new("Parameter 'path' not specified") unless params.key?('path') || params['path'].empty?
    
    begin
      @branch = params.key?('branch') ? params['branch'] : 'master'
      refresh = params.key?('refresh') ? params['refresh'].to_i : 600
      
      repos_path = File.join(Rails.root, 'tmp', 'gitrepos')
      FileUtils.mkdir(repos_path) unless File.exists?(repos_path)
      
      repo_path = File.join(repos_path, "#{Digest::MD5.hexdigest(params['path'])}_#{namespace}")
      
      # Pull if existing tmp-repo has same remote origin
      if File.exists?(File.join(repo_path, '.git'))
        @repo = GitRepo.new(repo_path) rescue nil
        if @repo && @repo.remotes.key?('origin') && @repo.remotes['origin'][:url] == params['path']
          logger.info "Reusing git repository at '#{repo_path}'"
          @repo.pull('origin', @branch)
        else
          @repo = nil
          FileUtils.rm_rf(repo_path)
        end
      end
      
      unless @repo
        logger.info "Cloning git repository from '#{params['path']}'"
        @repo = GitRepo.clone(params['path'], repo_path)
      end
      
      @repo.checkout(@branch)
      
      @repo.git_timeout = 10
      @repo.git_max_size = 26214400
      
      Thread.new do
        while true do
          sleep refresh
          git_pull rescue nil
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
    @repo.log(@branch).each do |commit|
      commit[:changes].each do |change|
        namespaces << change[:file].split('/', 2).first.strip
      end
    end
    namespaces = namespaces.compact.uniq
    namespaces
  end
  cache :namespaces

  private

  def exists?(obj, revision=nil)
    obj = normalize(obj)
    revision ||= 'HEAD'
    
    return @repo.log(revision, obj, :limit => 1).first[:changes].first[:mode] != 'D' rescue false
  end
  cache :exists?

  def contents(obj, revision=nil)
    obj = normalize(obj)
    revision ||= 'HEAD'
    
    raise PageNotExists unless exists?(obj, revision)
    
    @repo.show(revision, obj)
  end
  cache :contents

  def save(obj, contents, message, user)
    obj = normalize(obj)
    message = '-' if message.nil? || message.empty?
    
    FileUtils.mkdir_p(File.join(@repo.working_dir, path(obj)))
    File.open(File.join(@repo.working_dir, obj), 'w') do |f|
      f.write(contents)
    end
    
    @repo.add(obj)
    @repo.commit(message, format_user(user), obj)
    git_push
    
    flush(:exists?, obj, nil)
    flush(:contents, obj, nil)
    flush(:revisions, obj)
    flush(:changes)
    flush(:namespaces)
  end

  def rename(old_obj, new_obj, message, user)
    old_obj = normalize(old_obj)
    new_obj = normalize(new_obj)
    message = '-' if message.nil? || message.empty?
    
    raise ProviderError.new('Target exists') if exists?(new_obj)
    
    FileUtils.mkdir_p(File.join(@repo.working_dir, path(new_obj)))
    File.open(File.join(@repo.working_dir, new_obj), 'w') do |f|
      f.write(contents(old_obj))
    end
    
    @repo.remove(old_obj)
    @repo.add(new_obj)
    @repo.commit(message, format_user(user), [old_obj, new_obj])
    git_push
    
    flush(:exists?)
    flush(:contents, old_obj, nil)
    flush(:contents, new_obj, nil)
    flush(:revisions, old_obj)
    flush(:revisions, new_obj)
    flush(:changes)
    flush(:namespaces)
  end

  def delete(obj, message, user)
    obj = normalize(obj)
    message = '-' if message.nil? || message.empty?
    
    raise PageNotExists unless exists?(obj)
    
    @repo.remove(obj)
    @repo.commit(message, format_user(user), obj)
    git_push
    
    flush(:exists?, obj, nil)
    flush(:contents, obj, nil)
    flush(:revisions, obj)
    flush(:changes)
    flush(:namespaces)
  end

  def revisions(obj)
    obj = normalize(obj)
    
    raise PageNotExists unless exists?(obj)
    
    parts = obj.split('/')
    
    revs = []
    @repo.log(@branch, obj).each do |commit|
      mode = commit[:changes].first[:mode]
      revs << Revision.new(
          ((parts.length == 2) ? Page.new(:namespace => parts[0], :name => parts[1]) : Attachment.new(:namespace => parts[0], :page => parts[1], :name => parts[2])),
          commit[:id].downcase,
          commit[:id][0..6].upcase,
          (mode == 'D') ? -1 : size(obj, commit[:id]),
          Raki::Authenticator.user_for(:username => commit[:author][:name], :email => commit[:author][:email]),
          commit[:date],
          commit[:message],
          (mode == 'D') ? :deleted : nil
        )
    end
    
    revs
  end
  cache :revisions

  def all(dir, revision=nil)
    dir = normalize(dir)
    revision ||= 'HEAD'
    
    files = []
    @repo.log(revision, dir).each do |commit|
      commit[:changes].each do |change|
        parts = change[:file].split('/')
        files << normalize(parts[1]) if parts.length == 2
      end
    end
    
    files.sort { |a,b| a <=> b }
  end
  cache :all

  def changes(namespace, dir, options={}, page=nil)
    dir = normalize(dir)
    changes = []
    begin
      @repo.log(@branch, dir).each do |commit|
        break if options[:since] && options[:since] <= commit.authored_date
        commit[:changes].each do |change|
          if page
            changes << Revision.new(
                Attachment.find(namespace, page, normalize(File.basename(change[:file])), commit[:id]),
                commit[:id],
                commit[:id][0..6].upcase,
                (commit[:mode] == 'D') ? -1 : size(commit[:file], commit[:id]),
                Raki::Authenticator.user_for(:username => commit[:author][:name], :email => commit[:author][:email]),
                commit[:date],
                commit[:message],
                (commit[:mode] == 'D') ? :deleted : nil
              )
          else
            changes << Revision.new(
                Page.find(namespace, normalize(File.basename(change[:file])), commit[:id]),
                commit[:id],
                commit[:id][0..6].upcase,
                (commit[:mode] == 'D') ? -1 : size(commit[:file], commit[:id]),
                Raki::Authenticator.user_for(:username => commit[:author][:name], :email => commit[:author][:email]),
                commit[:date],
                commit[:message],
                (commit[:mode] == 'D') ? :deleted : nil
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
  
  def size(obj, revision)
    @repo.show(revision, obj).size
  end
  cache :size, :ttl => 3600
  
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
    "#{user.username} <#{user.email}>"
  end
  
  def git_push
    @repo.push('origin', @branch)
    logger.debug "Pushed to '#{@repo.remotes['origin'][:url]}'"
  end
  
  def git_pull
    @repo.pull('origin', @branch)
    logger.debug "Pulled from '#{@repo.remotes['origin'][:url]}'"
  end

  def logger
    Rails.logger
  end
  
end
