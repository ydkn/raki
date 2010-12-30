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
      
      @repo.checkout(@branch) rescue nil
      
      @repo.git_timeout = (params['timeout'] || 10).to_i
      
      Thread.new do
        while true do
          sleep refresh
          git_pull rescue nil
        end
      end
    rescue => e
      Rails.logger.error(e)
      raise ProviderError.new("Failed to initialize GIT repository: #{e.to_s}")
    end
  end

  def page_exists?(namespace, name, revision=nil)
    exists?("#{namespace.to_s}/#{name.to_s}", revision)
  end

  def page_contents(namespace, name, revision=nil)
    contents("#{namespace.to_s}/#{name.to_s}", revision)
  end
  cache :page_contents

  def page_revisions(namespace, name, options={})
    revisions("#{namespace.to_s}/#{name.to_s}", options)
  end

  def page_save(namespace, name, contents, message, user)
    save("#{namespace.to_s}/#{name.to_s}", contents, message, user)
  end

  def page_rename(old_namespace, old_name, new_namespace, new_name, user)
    msg = (old_namespace.to_s == new_namespace.to_s) ? "#{old_name.to_s} ==> #{new_name.to_s}" : "#{old_namespace.to_s}/#{old_name.to_s} ==> #{new_namespace.to_s}/#{new_name.to_s}"
    rename("#{old_namespace.to_s}/#{old_name.to_s}", "#{new_namespace.to_s}/#{new_name.to_s}", msg, user)
  end

  def page_delete(namespace, name, user)
    delete("#{namespace.to_s}/#{name.to_s}", "#{name.to_s} ==> /dev/null", user)
  end

  def page_all(namespace)
    all(namespace.to_s)
  end

  def page_changes(namespace, options={})
    changes(namespace.to_s, namespace.to_s, options)
  end
  
  def page_diff(namespace, page, revision_from=nil, revision_to=nil)
    diff("#{namespace.to_s}/#{page.to_s}", revision_from, revision_to)
  end

  def attachment_exists?(namespace, page, name, revision=nil)
    exists?("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", revision)
  end

  def attachment_contents(namespace, page, name, revision=nil)
    contents("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", revision)
  end

  def attachment_revisions(namespace, page, name, options={})
    revisions("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", options)
  end

  def attachment_save(namespace, page, name, contents, message, user)
    save("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", contents, message, user)
  end

  def attachment_delete(namespace, page, name, user)
    delete("#{namespace.to_s}/#{page.to_s}_att/#{name.to_s}", "#{page.to_s}/#{name.to_s} ==> /dev/null", user)
  end

  def attachment_all(namespace, page)
    all("#{namespace.to_s}/#{page.to_s}_att", 3)
  end

  def attachment_changes(namespace, page=nil, options={})
    unless page
      changes = []
      page_all(namespace).each do |page|
        changes += changes(namespace, "#{namespace.to_s}/#{page.to_s}_att", options, true)
      end
      changes.sort!{|a,b| a[:date] <=> b[:date] }
    else
      changes(namespace, "#{namespace.to_s}/#{page.to_s}_att", options, true)
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
    
    @repo.log(revision, obj, :limit => 1).first[:changes].first[:mode] != 'D' rescue false
  end
  cache :exists?

  def contents(obj, revision=nil)
    obj = normalize(obj)
    revision ||= 'HEAD'
    
    raise PageNotExists unless exists?(obj, revision)
    
    @repo.cat(revision, obj)
  end

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
    flush(:revisions)
    flush(:page_contents)
    flush(:namespaces)
  end

  def rename(old_obj, new_obj, message, user)
    old_obj = normalize(old_obj)
    new_obj = normalize(new_obj)
    message = '-' if message.nil? || message.empty?
    
    raise ProviderError.new('Target exists') if exists?(new_obj)
    
    @repo.move(old_obj, new_obj)
    @repo.commit(message, format_user(user), [old_obj, new_obj])
    git_push
    
    flush(:exists?)
    flush(:page_contents)
    flush(:revisions)
    flush(:revisions)
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
    flush(:page_contents)
    flush(:revisions)
    flush(:changes)
    flush(:namespaces)
  end

  def revisions(obj, options)
    obj = normalize(obj)
    
    raise PageNotExists unless exists?(obj)
    
    parts = obj.split('/')
    
    revs = []
    @repo.log(@branch, obj, :limit => options[:limit], :since => options[:since]).each do |commit|
      mode = case commit[:changes].first[:mode]
        when 'D'
          :deleted
        when 'A'
          :created
        when 'M'
          :modified
        else
          :none
      end
      revs << {
        :id => commit[:id].downcase,
        :version => commit[:id][0..6].upcase,
        :date => commit[:date],
        :message => commit[:message],
        :user => user_for(commit[:author]),
        :mode => mode,
        :size => size(obj, commit[:id]),
        :type => (parts.length == 2) ? :page : :attachment
      }
    end
    
    revs
  end
  cache :revisions

  def all(dir, fp=2)
    dir = normalize(dir)
    revision ||= 'HEAD'
    
    files = []
    @repo.tree(revision, dir).each do |child|
      files << child[:filename] if child[:type] == 'blob'
    end
    
    files.sort { |a,b| a <=> b }
  end
  cache :all

  def changes(namespace, dir, options={}, att=false)
    dir = normalize(dir)
    
    changes = []
    @repo.log(@branch, dir, :limit => options[:limit], :since => options[:since]).each do |commit|
      commit[:changes].each do |change|
        next if !att && change[:file] =~ /_att\//
        next unless exists?(change[:file])
        mode = case change[:mode]
          when 'D'
            :deleted
          when 'A'
            :created
          when 'M'
            :modified
          else
            :none
          end
        parts = change[:file].split('/')
        type = att ? :attachment : :page
        changes << {
          :id => commit[:id].downcase,
          :version => commit[:id][0..6].upcase,
          :date => commit[:date],
          :message => commit[:message],
          :user => user_for(commit[:author]),
          :mode => mode,
          :size => size(change[:file], commit[:id]),
          :type => type,
          :page => (type == :attachment) ? {:namespace => namespace, :name => parts[1].gsub(/_att$/, '')} : {:namespace => namespace, :name => parts[1]},
          :attachment => parts[2]
        }
      end
    end
    
    changes
  end
  cache :changes
  
  def size(obj, revision)
    return nil unless exists?(obj, revision)
    @repo.size(revision, obj)
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
  
  def user_for(commit_author)
    Raki::Authenticator.user_for(:username => commit_author[:name], :email => commit_author[:email])
  end
  cache :user_for, :ttl => 30
  
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
