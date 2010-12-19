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
require 'popen4'

class GitRepo
  
  GIT_BINARY = `/usr/bin/env which git`.strip
  GIT_TIMEOUT = 10
  GIT_MAX_SIZE = 5242880
  
  class GitError < StandardError; end
  class GitBinaryError < GitError; end
  
  include Cacheable
  
  attr_accessor :git_timeout, :git_max_size, :git_binary
  attr_reader :path, :working_dir
  
  def initialize(path)
    unless File.exists?(path)
      raise GitError.new 'Git repository doesn\'t exist'
    end
    
    if File.exists?(File.join(path, '.git'))
      @path = File.join(path, '.git')
      @working_dir = path
    else
      @path = path
    end
    
    @git_timeout = GIT_TIMEOUT
    @git_max_size = GIT_MAX_SIZE
    @git_binary = GIT_BINARY
  end
  
  def remotes
    remotes = {}
    remote = {}
    File.open(File.join(@path, 'config'), 'r').each_line do |line|
      if remote.key?(:name) && line =~ /url\s*=\s*(.+)/i
        remote[:url] = $1
      elsif line =~ /\[remote "([a-z0-9_-]+)"\]/i
        remote[:name] = $1
        remote.delete(:url)
      elsif line =~ /\[.*\]/
        remote = {}
      end
      if remote.key?(:name) && remote.key?(:url)
        remotes[remote[:name]] = {:url => remote[:url]}
      end
    end
    remotes
  end
  cache :remotes
  
  def checkout(refspec)
    out, err = run_git(['checkout', refspec])
    true
  end
  
  def add(pathspec)
    out, err = run_git(['add', "\"#{pathspec}\""])
    true
  end
  
  def remove(pathspec)
    out, err = run_git(['rm', "\"#{pathspec}\""])
    true
  end
  
  def commit(message, user, pathspec=nil)
    out, err = run_git(['commit', '-m', "\"#{message.to_s}\"", "--author=\"#{user.to_s}\"", '"' + (pathspec.respond_to?(:join) ? pathspec.join('" "') : pathspec) + '"'])
    true
  end
  
  def pull(remote, branch)
    out, err = run_git(['pull', remote, branch])
    true
  end
  
  def push(remote, branch)
    out, err = run_git(['push', remote, branch])
    true
  end
  
  def log(refspec, pathspec=nil, options={})
    params = ['log', '--raw', '--full-index']
    params << "-n #{options[:limit]}" if options[:limit]
    params << "--since=#{options[:since].strftime("%Y-%m-%d %H:%M:%S")}" if options[:since]
    params << refspec
    
    out, err = run_git(params, ["\"#{pathspec}\""])
    
    raise GitBinaryError.new(err) unless err.empty?
    
    commits = []
    commit = {:changes => []}
    out.split("\n").each do |line|
      line.strip!
      if line =~ /^commit ([a-f0-9]+)$/i
        if commit.key?(:id) && commit.key?(:author) && commit.key?(:date)
          commit[:message] = commit[:message].join("\n").strip
          commits << commit
          commit = {:changes => []}
        end
        commit[:id] = $1
        commit[:message] = []
      elsif line =~ /^Author:\s+(.+) <(.+)>/i
        commit[:author] = {:name => $1, :email => $2}
      elsif line =~ /^Date:\s+(.+)/i
        commit[:date] = Time.parse($1.strip)
      elsif line =~ /^:\d{6} \d{6} [0-9a-f]+\.\.\. [0-9a-f]+\.\.\. ([a-z])\s+(.+)/i
        commit[:changes] << {:mode => $1.strip, :file => $2.strip}
      else
        commit[:message] << line.strip unless line.strip.blank?
      end
    end
    if commit.key?(:id) && commit.key?(:author) && commit.key?(:date)
      commit[:message] = commit[:message].join("\n").strip
      commits << commit
    end
    
    commits
  end
  
  def show(refspec, pathspec)
    out, err = run_git(['show', "#{refspec}:\"#{pathspec}\""])
    raise GitBinaryError.new(err) unless err.empty?
    out
  end
  
  def self.clone(url, path)
    out, err = run_git(['clone', url, path])
    raise GitBinaryError.new(err) unless err.split("\n").select{|l| l =~ /^fatal: /}.empty?
    GitRepo.new(path)
  end
  
  private
  
  def run_git(cmds, args=[], options={})
    options[:working_dir] ||= working_dir
    options[:path] ||= path
    options[:timeout] ||= git_timeout
    options[:max_size] ||= git_max_size
    options[:binary] ||= git_binary
    
    GitRepo.run_git(cmds, args, options)
  end
  
  def self.run_git(cmds, args=[], options={})
    command = ''
    command += 'cd ' + options[:working_dir] + ' && ' if options[:working_dir]
    command += (options[:binary] || GIT_BINARY) + ' '
    command += options[:path] + ' ' if !options[:working_dir] && options[:path]
    command += cmds.join(' ')
    command += ' -- ' + args.join(' ') if args && !args.empty?
    
    timeout = options[:timeout] || GIT_TIMEOUT
    max_size = options[:max_size] || GIT_MAX_SIZE
    
    out, err = '', ''
    read = 0
    POpen4.popen4(command) do |stdout, stderr, stdin, pid|
      Timeout.timeout(timeout) do
        while tmp = stdout.read(1024)
          out += tmp
          raise 'Max size exceeded' if (read += tmp.size) > max_size
        end
      end
      
      while tmp = stderr.read(1024)
        err += tmp
      end
    end
    
    [out, err]
  rescue => e
    raise e.to_s
  end
  
end