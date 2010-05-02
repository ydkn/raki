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

  def initialize(params)
    @path = params['path']
    @git_path = @path
    @git_path = "#{@path}/.git" unless Dir[@path].nil?
    check_repository
  end

  def page_exists?(name, revision=nil)
    logger.debug("Checking if page exists: #{{:name => name, :revision => revision}}")
    exists?('pages', name, revision)
  end

  def page_contents(name, revision=nil)
    logger.debug("Fetching contents of page: #{{:name => name, :revision => revision}}")
    contents("pages/#{name}", revision)
  end

  def page_revisions(name)
    logger.debug("Fetching revisions for page #{{:name => name}}")
    revisions("pages/#{name}")
  end

  def page_save(name, contents, message, user)
    logger.debug("Saving page: #{{:name => name, :contents => contents, :message => message, :user => user}}")
    save("pages/#{name}", contents, message, user)
  end

  def page_rename(old_name, new_name, user)
    logger.debug("Renaming page: #{{:from => old_name, :to => new_name, :user => user}}")
    rename("pages/#{old_name}", "pages/#{new_name}", "#{old_name} ==> #{new_name}", user)
  end

  def page_delete(name, user)
    logger.debug("Deleting page: #{{:page => name, :user => user}}")
    delete("pages/#{name}", "#{name} ==> /dev/null", user)
  end

  def page_all
    logger.debug("Fetching all pages")
    all('pages')
  end

  def page_changes(amount=0)
    logger.debug("Fetching all page changes: #{{:limit => amount}}")
    changes(:page, 'pages', amount)
  end

  def userpage_exists?(user, revision=nil)
    logger.debug("Checking if userpage exists: #{{:userpage => user, :revision => revision}}")
    exists?('users', user, revision)
  end

  def userpage_contents(user, revision=nil)
    logger.debug("Fetching contents of userpage: #{{:username => user, :revision => revision}}")
    contents("users/#{user}", revision)
  end

  def userpage_revisions(user)
    logger.debug("Fetching revisions for userpage #{{:username => user}}")
    revisions("users/#{user}")
  end

  def userpage_save(username, contents, message, user)
    logger.debug("Saving userpage: #{{:username => username, :contents => contents, :message => message, :user => user}}")
    save("users/#{username}", contents, message, user)
  end

  def userpage_delete(username, user)
    logger.debug("Deleting userpage: #{{:userpage => username, :user => user}}")
    delete("users/#{username}", "#{user} ==> /dev/null", user)
  end

  def userpage_all
    logger.debug("Fetching all userpages")
    all('users')
  end

  def userpage_changes(amount=0)
    logger.debug("Fetching all userpage changes: #{{:limit => amount}}")
    changes(:userpage, 'users', amount)
  end

  private

  def check_repository
    cmd = "#{GIT_BIN} --git-dir #{@git_path} status 2> /dev/null"
    output = ""
    shell_cmd(cmd) do |line|
      output += line
    end
    raise ProviderError.new 'Invalid git repository' if output.empty?
  end

  def exists?(dir, name, revision=nil)
    check_repository
    name = format_obj(name)
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{shell_quote(revision)}:#{dir}"
    shell_cmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+\w+\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        return true if $1 == name
      end
    end
    false
  end

  def contents(obj, revision=nil)
    check_repository
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} show #{shell_quote(revision)}:#{format_obj(obj)}"
    contents = ""
    shell_cmd(cmd) do |line|
      contents += line
    end
    contents
  end

  def save(obj, contents, message, user)
    check_repository
    obj = format_obj(obj)
    message = '-' if message.empty?
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
  end

  def rename(old_obj, new_obj, message, user)
    check_repository
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
  end

  def delete(obj, message, user)
    check_repository
    obj = format_obj(obj)
    File.delete("#{@path}/#{shell_quote(obj)}")
    cmd = "cd #{@path} && #{GIT_BIN} commit -m \"#{shell_quote(message)}\" --author=\"#{shell_quote(user.username)} <#{shell_quote(user.email)}>\" \"#{shell_quote(obj)}\""
    shell_cmd(cmd) do |line|
      #nothing
    end
  end

  def revisions(obj)
    check_repository
    revs = []
    changeset = {}
    cmd = "#{GIT_BIN} --git-dir #{@git_path} log --reverse --raw --date=iso --all -- \"#{shell_quote(format_obj(obj))}\""
    shell_cmd(cmd) do |line|
      if line =~ /^commit ([0-9a-f]{40})$/
        if(changeset.length == 4)
          revs << Revision.new(
            changeset[:commit],
            changeset[:commit][0..7].upcase,
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
    if(changeset.length == 4)
      revs << Revision.new(
        changeset[:commit],
        changeset[:commit][0..7].upcase,
        changeset[:author],
        changeset[:date],
        changeset[:message].strip
      )
    end
    revs
  end

  def all(dir, revision=nil)
    check_repository
    objs = []
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{shell_quote(revision)}:#{dir}"
    shell_cmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+\w+\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        page_name = $1
        objs << page_name unless page_name =~ /^\./
      end
    end
    objs
  end

  def changes(type, dir, amount=0)
    changes = []
    all(dir).each do |obj|
      revisions("#{dir}/#{obj}").each do |revision|
        changes << Change.new(type, obj, revision)
      end
    end
    changes
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
