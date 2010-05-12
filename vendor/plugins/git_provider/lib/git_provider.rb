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
    logger.debug("Fetching revisions for page: #{{:name => name}}")
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

  def page_changes(amount=nil)
    logger.debug("Fetching all page changes: #{{:limit => amount}}")
    changes(:page, 'pages', amount)
  end

  def page_attachment_exists?(page, name, revision=nil)
    logger.debug("Checking if page attachment exists: #{{:page => page, :name => name, :revision => revision}}")
    exists?("attachments/pages/#{page}", name, revision)
  end

  def page_attachment_contents(page, name, revision=nil)
    logger.debug("Fetching contents of page attachment: #{{:page => page, :name => name, :revision => revision}}")
    contents("attachments/pages/#{page}/#{name}", revision)
  end

  def page_attachment_revisions(page, name)
    logger.debug("Fetching revisions for page attachment: #{{:page => page, :name => name}}")
    revisions("attachments/pages/#{page}/#{name}")
  end

  def page_attachment_save(page, name, contents, message, user)
    logger.debug("Saving page attachment: #{{:page => page, :name => name, :contents => contents, :message => message, :user => user}}")
    save("attachments/pages/#{page}/#{name}", contents, message, user)
  end

  def page_attachment_delete(page, name, user)
    logger.debug("Deleting page attachment: #{{:page => page, :name => name, :user => user}}")
    delete("attachments/pages/#{page}/#{name}", "#{page}/#{name} ==> /dev/null", user)
  end

  def page_attachment_all(page=nil)
    logger.debug("Fetching all page attachments: #{{:page => page}}")
    if page.nil?
      all('attachments/pages')
    else
      all("attachments/pages/#{page}")
    end
  end

  def page_attachment_changes(page=nil, amount=nil)
    logger.debug("Fetching all page attachment changes: #{{:page => page, :limit => amount}}")
    if page.nil?
      changes(:page, 'attachments/pages', amount)
    else
      changes(:page, "attachments/pages/#{page}", amount)
    end
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
    logger.debug("Fetching revisions for userpage: #{{:username => user}}")
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

  def userpage_changes(amount=nil)
    logger.debug("Fetching all userpage changes: #{{:limit => amount}}")
    changes(:user_page, 'users', amount)
  end

  def userpage_attachment_exists?(user, name, revision=nil)
    logger.debug("Checking if userpage attachment exists: #{{:user => user, :name => name, :revision => revision}}")
    exists?("attachments/users/#{user}", name, revision)
  end

  def userpage_attachment_contents(user, name, revision=nil)
    logger.debug("Fetching contents of userpage attachment: #{{:user => user, :name => name, :revision => revision}}")
    contents("attachments/users/#{user}/#{name}", revision)
  end

  def userpage_attachment_revisions(user, name)
    logger.debug("Fetching revisions for userpage attachment: #{{:user => user, :name => name}}")
    revisions("attachments/users/#{user}/#{name}")
  end

  def userpage_attachment_save(username, name, contents, message, user)
    logger.debug("Saving userpage attachment: #{{:username => username, :name => name, :contents => contents, :message => message, :user => user}}")
    save("attachments/users/#{username}/#{name}", contents, message, user)
  end

  def userpage_attachment_delete(username, name, user)
    logger.debug("Deleting userpage attachment: #{{:username => username, :name => name, :user => user}}")
    delete("attachments/users/#{username}/#{name}", "#{username}/#{name} ==> /dev/null", user)
  end

  def userpage_attachment_all(user=nil)
    logger.debug("Fetching all userpage attachments: #{{:user => user}}")
    if user.nil?
      all('attachments/users')
    else
      all("attachments/users/#{user}")
    end
  end

  def userpage_attachment_changes(user=nil, amount=nil)
    logger.debug("Fetching all userpage attachment changes: #{{:user => user, :limit => amount}}")
    if user.nil?
      changes(:user_page, 'attachments/users', amount)
    else
      changes(:user_page, "attachments/users/#{user}", amount)
    end
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
      if line.chomp.to_s =~ /^\d+\s+\w+\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        return true if $1 == name
      end
    end
    false
  end

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

  def all(dir, revision=nil)
    check_repository
    check_obj(dir)
    objs = []
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{shell_quote(revision)}:#{dir}"
    shell_cmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+\w+\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        page_name = $1
        objs << page_name unless page_name =~ /^\./
      end
    end
    objs.sort { |a,b| a <=> b }
  end

  def changes(type, dir, amount=0)
    check_repository
    check_obj(dir)
    changes = []
    all(dir).each do |obj|
      revisions("#{dir}/#{obj}").each do |revision|
        changes << Change.new(type, obj, obj, revision)
      end
    end
    changes = changes.sort { |a,b| b.revision.date <=> a.revision.date }
    if amount.nil?
      changes
    else
      changes[0..(amount-1)]
    end
  end

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
