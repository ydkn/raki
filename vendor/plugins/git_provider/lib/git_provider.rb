# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
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

class GitProvider < Raki::AbstractProvider
  GIT_BIN = 'git'
  
  extend Cacheable
  include Cacheable

  def initialize(params)
    @path = params['path']
    @git_path = @path
    @git_path = "#{@path}/.git" unless Dir[@path].nil?
    check_repository
  end

  def page_exists?(type, name, revision=nil)
    logger.debug("Checking if page exists: #{{:type => type, :name => name, :revision => revision}}")
    exists?(type.to_s, name, revision)
  end

  def page_contents(type, name, revision=nil)
    logger.debug("Fetching contents of page: #{{:type => type, :name => name, :revision => revision}}")
    contents("#{type.to_s}/#{name}", revision)
  end

  def page_revisions(type, name)
    logger.debug("Fetching revisions for page: #{{:type => type, :name => name}}")
    revisions("#{type.to_s}/#{name}")
  end

  def page_save(type, name, contents, message, user)
    logger.debug("Saving page: #{{:type => type, :name => name, :contents => contents, :message => message, :user => user}}")
    save("#{type.to_s}/#{name}", contents, message, user)
  end

  def page_rename(type, old_name, new_name, user)
    logger.debug("Renaming page: #{{:type => type, :from => old_name, :to => new_name, :user => user}}")
    rename("#{type.to_s}/#{old_name}", "#{type}/#{new_name}", "#{old_name} ==> #{new_name}", user)
  end

  def page_delete(type, name, user)
    logger.debug("Deleting page: #{{:type => type, :page => name, :user => user}}")
    delete("#{type.to_s}/#{name}", "#{name} ==> /dev/null", user)
  end

  def page_all(type)
    logger.debug("Fetching all pages")
    all(type.to_s)
  end

  def page_changes(type, amount=nil)
    logger.debug("Fetching all page changes: #{{:type => type, :limit => amount}}")
    changes(type, type.to_s, amount)
  end
  
  def page_diff(type, page, revision_from, revision_to=nil)
    logger.debug("Fetching diff: #{{:type => type, :page => page, :revision_from => revision_from, :revision_to => revision_to}}")
    diff("#{type}/#{page}", revision_from, revision_to)
  end

  def attachment_exists?(type, page, name, revision=nil)
    logger.debug("Checking if page attachment exists: #{{:type => type, :page => page, :name => name, :revision => revision}}")
    exists?("#{type.to_s}/#{page}_att", name, revision)
  end

  def attachment_contents(type, page, name, revision=nil)
    logger.debug("Fetching contents of page attachment: #{{:type => type, :page => page, :name => name, :revision => revision}}")
    contents("#{type.to_s}/#{page}_att/#{name}", revision)
  end

  def attachment_revisions(type, page, name)
    logger.debug("Fetching revisions for page attachment: #{{:type => type, :page => page, :name => name}}")
    revisions("#{type.to_s}/#{page}_att/#{name}")
  end

  def attachment_save(type, page, name, contents, message, user)
    logger.debug("Saving page attachment: #{{:type => type, :page => page, :name => name, :contents => contents, :message => message, :user => user}}")
    save("#{type.to_s}/#{page}_att/#{name}", contents, message, user)
  end

  def attachment_delete(type, page, name, user)
    logger.debug("Deleting page attachment: #{{:type => type, :page => page, :name => name, :user => user}}")
    delete("#{type.to_s}/#{page}_att/#{name}", "#{page}/#{name} ==> /dev/null", user)
  end

  def attachment_all(type, page)
    logger.debug("Fetching all page attachments: #{{:type => type, :page => page}}")
    all("#{type}/#{page}_att")
  end

  def attachment_changes(type, page, amount=nil)
    logger.debug("Fetching all page attachment changes: #{{:type => type, :page => page, :limit => amount}}")
    changes(type, "#{type}/#{page}_att", amount, page)
  end
  
  def types
    check_repository
    revision = 'HEAD'
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{shell_quote(revision)}"
    types = []
    shell_cmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+(\w+)\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        types << $2.to_sym if $1 == 'tree'
      end
    end
    types
  end
  cache :types

  private

  def check_repository
    cmd = "#{GIT_BIN} --git-dir #{@git_path} status 2> /dev/null"
    output = ""
    shell_cmd(cmd) do |line|
      output += line
    end
    raise ProviderError.new 'Invalid git repository' if output.empty?
  end
  cache :check_repository

  def check_obj(obj)
    raise ProviderError.new 'Invalid filename' if obj.nil? || obj.empty?
  end

  def check_user(user)
    raise ProviderError.new 'Invalid user' if user.nil? || !user.is_a?(User)
  end

  def check_contents(contents)
    raise ProviderError.new 'Invalid content' if contents.nil?
  end

  def exists?(dir, name, revision=nil)
    check_repository
    check_obj(name)
    dir = '' if dir.nil?
    name = format_obj(name)
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{shell_quote(revision)}:#{dir}"
    shell_cmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+(\w+)\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        return true if ($1 == 'blob' && $2 == name)
      end
    end
    false
  end
  cache :exists?

  def contents(obj, revision=nil)
    check_repository
    check_obj(obj)
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} show #{shell_quote(revision)}:#{format_obj(obj)}"
    contents = ""
    shell_cmd(cmd) do |line|
      contents += line
    end
    contents
  end
  cache :contents

  def save(obj, contents, message, user)
    check_repository
    check_obj(obj)
    check_contents(contents)
    check_user(user)
    obj = format_obj(obj)
    message = '-' if message.nil? || message.empty?
    FileUtils.mkdir_p(path("#{@path}/#{obj}"))
    File.open("#{@path}/#{obj}", 'w') do |f|
      f.write(contents)
    end
    cmd = "cd #{@path} && #{GIT_BIN} add #{shell_quote(obj)}"
    shell_cmd(cmd) do |line|
      #nothing
    end
    cmd = "cd #{@path} && #{GIT_BIN} commit -m \"#{shell_quote(message)}\" --author=\"#{shell_quote(user.username)} <#{shell_quote(user.email)}>\" \"#{shell_quote(obj)}\""
    shell_cmd(cmd) do |line|
      #nothing
    end
    flush_cache(:exists?)
    flush_cache(:contents, obj, nil)
    flush_cache(:revisions, obj)
    flush_cache(:changes)
    flush_cache(:size, obj, nil)
    flush_cache(:types)
  end

  def rename(old_obj, new_obj, message, user)
    check_repository
    check_obj(old_obj)
    check_obj(new_obj)
    check_user(user)
    message = '-' if message.nil? || message.empty?
    old_obj = format_obj(old_obj)
    new_obj = format_obj(new_obj)
    File.open("#{@path}/#{shell_quote(new_obj)}", 'w') do |f|
      f.write(contents(old_obj))
    end
    File.delete("#{@path}/#{shell_quote(old_obj)}")
    cmd = "cd #{@path} && #{GIT_BIN} add #{shell_quote(new_obj)}"
    shell_cmd(cmd) do |line|
      #nothing
    end
    cmd = "cd #{@path} && #{GIT_BIN} commit -m \"#{shell_quote(message)}\" --author=\"#{shell_quote(user.username)} <#{shell_quote(user.email)}>\" \"#{shell_quote(old_obj)}\" \"#{shell_quote(new_obj)}\""
    shell_cmd(cmd) do |line|
      #nothing
    end
    flush_cache(:exists?)
    flush_cache(:revisions)
    flush_cache(:changes)
  end

  def delete(obj, message, user)
    check_repository
    check_obj(obj)
    check_user(user)
    message = '-' if message.nil? || message.empty?
    obj = format_obj(obj)
    File.delete("#{@path}/#{shell_quote(obj)}")
    cmd = "cd #{@path} && #{GIT_BIN} commit -m \"#{shell_quote(message)}\" --author=\"#{shell_quote(user.username)} <#{shell_quote(user.email)}>\" \"#{shell_quote(obj)}\""
    shell_cmd(cmd) do |line|
      #nothing
    end
    flush_cache(:exists?)
    flush_cache(:contents, obj, nil)
    flush_cache(:revisions, obj)
    flush_cache(:changes)
    flush_cache(:size, obj, nil)
    flush_cache(:types)
  end

  def revisions(obj)
    check_repository
    check_obj(obj)
    revs = []
    changeset = {}
    cmd = "#{GIT_BIN} --git-dir #{@git_path} log --reverse --raw --date=iso --all -- \"#{shell_quote(format_obj(obj))}\""
    shell_cmd(cmd) do |line|
      if line =~ /^commit ([0-9a-f]{40})$/
        if changeset.length == 4
          revs << Revision.new(
            changeset[:commit],
            changeset[:commit][0..7].upcase,
            size(obj, changeset[:commit]),
            changeset[:author],
            changeset[:date],
            changeset[:message].strip
          )
          changeset = {}
        end
        changeset[:commit] = $1
      elsif line =~ /^Author: ([^<]+) <([^>]+)>$/
        changeset[:author] = $1
      elsif line =~ /^Date:[ ]*(.+)$/
        changeset[:date] = Time.parse($1)
      elsif line =~ /^\s+(.+)$/
        if changeset[:message].nil?
          changeset[:message] = line
        else
          changeset[:message] += " #{line}"
        end
      end
    end
    if changeset.length == 4
      revs << Revision.new(
        changeset[:commit],
        changeset[:commit][0..7].upcase,
        size(obj, changeset[:commit]),
        changeset[:author],
        changeset[:date],
        changeset[:message].strip
      )
    end
    revs
  end
  cache :revisions

  def all(dir)
    check_repository
    check_obj(dir)
    objs = []
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{shell_quote(revision)}:#{dir}"
    shell_cmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+(\w+)\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        page_name = $2
        next unless $1 == 'blob'
        objs << page_name unless page_name =~ /^\./
      end
    end
    objs.sort { |a,b| a <=> b }
  end
  cache :all

  def changes(type, dir, amount=0, page=nil)
    check_repository
    check_obj(dir)
    changes = []
    all(dir).each do |obj|
      revisions("#{dir}/#{obj}").each do |revision|
        if page.nil?
          changes << Change.new(type, obj, revision)
        else
          changes << Change.new(type, page, revision, obj)
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
  
  def diff(obj, revision_from, revision_to=nil)
    check_repository
    check_obj(obj)
    revisions = revisions(obj)
    revision_from = revisions[revisions.length-2].id if revision_from.nil?
    if revision_to.nil?
      rev_from = nil
      revisions.each do |rev|
        rev_from = rev if rev.id == revision_from
      end
      revision_to = revisions[revisions.index(rev_from)-1].id
    end
    cmd = "#{GIT_BIN} --git-dir #{@git_path} diff #{shell_quote(revision_to)} #{shell_quote(revision_from)} -- #{shell_quote(obj)}"
    diff = []
    shell_cmd(cmd) do |line|
      diff << line
    end
    Diff.new(diff)
  end
  cache :diff

  def size(obj, revision=nil)
    check_obj(obj)
    revision = 'HEAD' if revision.nil?
    filename = file(obj)
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{shell_quote(revision)}:#{path(obj)}"
    shell_cmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+\w+\s+[0-9a-f]{40}\s+([0-9-]+)\s+(.+)$/
        return $1 if filename == $2
      end
    end
    nil
  end
  cache :size

  def path(obj)
    obj.gsub(/[^\/]+$/, '')
  end

  def file(obj)
    File.basename(obj)
  end

  def format_obj(obj)
    obj.gsub /\ /, '_'
  end

  def shell_cmd(cmd, &block)
    IO.popen(cmd, "r+") do |io|
      io.close_write
      io.each_line do |line|
        block.call(line) if block_given?
      end
    end
  end

  def shell_quote(str)
    str.gsub(/"/, '\\"')
  end

  def logger
    Rails.logger
  end
  
end
