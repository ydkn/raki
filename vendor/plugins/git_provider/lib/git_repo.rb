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

class GitRepo
  
  GIT_BINARY = `/usr/bin/env which git`.strip
  GIT_TIMEOUT = 10
  
  class GitError < StandardError; end
  class InvalidRepository < GitError; end
  class GitBinaryError < GitError; end
  
  include Cacheable
  
  attr_accessor :git_timeout, :git_binary
  attr_reader :path, :working_dir
  
  def initialize(path)
    unless File.exists?(path)
      raise InvalidRepository.new 'Git repository doesn\'t exist'
    end
    
    if File.exists?(File.join(path, '.git'))
      @path = File.join(path, '.git')
      @working_dir = path
    else
      @path = path
    end
    
    @git_timeout = GIT_TIMEOUT
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
    out, es = run_git(['checkout', shell_escape(refspec)])
    raise GitBinaryError unless es == 0
    true
  end
  
  def add(pathspec)
    out, es = run_git(['add', "\"#{shell_escape(pathspec)}\""])
    raise GitBinaryError unless es == 0
    true
  end
  
  def move(src, dest)
    target_dir = File.join(working_dir, File.dirname(dest))
    FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)
    out, es = run_git(['mv', "\"#{shell_escape(src)}\"", "\"#{shell_escape(dest)}\""])
    raise GitBinaryError unless es == 0
    true
  end
  
  def remove(pathspec)
    out, es = run_git(['rm', "\"#{shell_escape(pathspec)}\""])
    raise GitBinaryError unless es == 0
    true
  end
  
  def commit(message, user, pathspec=nil)
    pathspec = [pathspec] unless pathspec.respond_to?(:each)
    paths = pathspec.collect do |p|
      "\"#{shell_escape(p)}\""
    end.join(' ')
    
    out, es = run_git(['commit', '-m', "\"#{shell_escape(message)}\"", "--author=\"#{shell_escape(user)}\"", paths])
    
    raise GitBinaryError unless es == 0
    
    true
  end
  
  def pull(remote, branch)
    out, es = run_git(['pull', shell_escape(remote), shell_escape(branch)], [], {:timeout => 60})
    raise GitBinaryError unless es == 0 || es == 256
    true
  end
  
  def push(remote, branch)
    out, es = run_git(['push', shell_escape(remote), shell_escape(branch)], [], {:timeout => 60})
    raise GitBinaryError unless es == 0
    true
  end
  
  def log(refspec, pathspec=nil, options={})
    params = ['log', '--raw', '--full-index']
    params << "-n #{shell_escape(options[:limit].to_i)}" if options[:limit]
    params << "--since=\"#{shell_escape(options[:since].strftime("%Y-%m-%d %H:%M:%S"))}\"" if options[:since]
    params << refspec
    
    out, es = run_git(params, ["\"#{pathspec ? shell_escape(pathspec) : ''}\""])
    
    raise GitBinaryError unless es == 0
    
    commits = []
    commit = {:changes => []}
    out.split("\n").each do |line|
      line.strip!
      if line =~ /^commit ([a-f0-9]+)$/i
        if commit.key?(:id) && commit.key?(:author) && commit.key?(:date)
          commit[:message] = commit[:message].join("\n").strip
          commits << commit if !options[:since] || options[:since] <= commit[:date]
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
      commits << commit if !options[:since] || options[:since] <= commit[:date]
    end
    
    commits
  end
  
  def tree(refspec, pathspec)
    out, es = run_git(['ls-tree', "#{shell_escape(refspec)}:\"#{shell_escape(pathspec)}\""])
    raise GitBinaryError unless es == 0
    
    children = []
    out.split("\n").each do |line|
      line.strip!
      parts = line.split(/\s+/)
      children << {:type => parts[1], :filename => parts[3]}
    end
    
    children
  end
  
  def show(refspec, pathspec)
    out, es = run_git(['show', "#{shell_escape(refspec)}:\"#{shell_escape(pathspec)}\""])
    raise GitBinaryError unless es == 0
    out
  end
  
  def cat(refspec, pathspec)
    out, es = run_git(['cat-file', '-p', "#{shell_escape(refspec)}:\"#{shell_escape(pathspec)}\""])
    raise GitBinaryError unless es == 0
    out
  end
  
  def size(refspec, pathspec)
    out, es = run_git(['cat-file', '-s', "#{shell_escape(refspec)}:\"#{shell_escape(pathspec)}\""])
    raise GitBinaryError unless es == 0
    out.strip.to_i
  end
  
  def self.clone(url, path)
    out, es = run_git(['clone', shell_escape(url), shell_escape(path)], [], {:timeout => 60})
    raise GitBinaryError unless es == 0
    GitRepo.new(path)
  end
  
  private
  
  def shell_escape(string)
    self.class.shell_escape(string)
  end
  
  def run_git(cmds, args=[], options={})
    options[:working_dir] ||= working_dir
    options[:path] ||= path
    options[:timeout] ||= git_timeout
    options[:binary] ||= git_binary
    
    self.class.run_git(cmds, args, options)
  end
  
  def self.run_git(cmds, args=[], options={})
    command = ''
    command += 'cd ' + options[:working_dir] + ' && ' if options[:working_dir]
    command += (options[:binary] || GIT_BINARY) + ' '
    command += options[:path] + ' ' if !options[:working_dir] && options[:path]
    command += cmds.join(' ')
    command += ' -- ' + args.join(' ') if args && !args.empty?
    command += ' 2>/dev/null' unless RUBY_PLATFORM =~ /mswin/i
    
    timeout = options[:timeout] || GIT_TIMEOUT
    
    out = ''
    ret = -1
    Timeout.timeout(timeout) do
      out = `#{command}`
      ret = $?.to_i
    end
    
    [out, ret]
  rescue => e
    raise GitBinaryError.new(e)
  end
  
  def self.shell_escape(string)
    string = string.to_s
    
    ['\\', ';', '"', "'", '(', ')'].each do |c|
      string.gsub!(c, "\\\\#{c}")
    end
    
    string
  end
  
end