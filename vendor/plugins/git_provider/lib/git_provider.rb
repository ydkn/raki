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
    check_repository
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{shell_quote(revision)}:pages"
    shell_cmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+\w+\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        return true if $1 == name
      end
    end
    false
  end

  def page_contents(name, revision=nil)
    check_repository
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} show #{shell_quote(revision)}:pages/#{name}"
    contents = ""
    shell_cmd(cmd) do |line|
      contents += line
    end
    contents
  end

  def page_revisions(name)
    check_repository
    revisions("pages/#{name}")
  end

  def page_save(name, contents, message, user)
    check_repository
    message = '-' if message.empty?
    File.open("#{@path}/pages/#{shell_quote(name)}", 'w') do |f|
      f.write(contents)
    end
    cmd = "cd #{@path} && #{GIT_BIN} add pages/#{shell_quote(name)}"
    shell_cmd(cmd) do |line|
      #nothing
    end
    cmd = "cd #{@path} && #{GIT_BIN} commit -m \"#{shell_quote(message)}\" --author=\"#{shell_quote(user.username)} <#{shell_quote(user.email)}>\" pages/#{shell_quote(name)}"
    shell_cmd(cmd) do |line|
      #nothing
    end
  end

  def page_rename(old_name, new_name, user)
    check_repository
    File.open("#{@path}/pages/#{shell_quote(new_name)}", 'w') do |f|
      f.write(page_contents(old_name))
    end
    File.delete("#{@path}/pages/#{shell_quote(old_name)}")
    cmd = "cd #{@path} && #{GIT_BIN} add pages/#{shell_quote(new_name)}"
    shell_cmd(cmd) do |line|
      #nothing
    end
    cmd = "cd #{@path} && #{GIT_BIN} commit -m \"#{shell_quote(old_name)} ==> #{shell_quote(new_name)}\" --author=\"#{shell_quote(user.username)} <#{shell_quote(user.email)}>\" pages/#{shell_quote(old_name)} pages/#{shell_quote(new_name)}"
    shell_cmd(cmd) do |line|
      #nothing
    end
  end

  def page_delete(name, user)
    check_repository
    File.delete("#{@path}/pages/#{shell_quote(name)}")
    cmd = "cd #{@path} && #{GIT_BIN} commit -m \"#{shell_quote(name)} ==> /dev/null\" --author=\"#{shell_quote(user.username)} <#{shell_quote(user.email)}>\" pages/#{shell_quote(name)}"
    shell_cmd(cmd) do |line|
      #nothing
    end
  end

  private

  def revisions(object)
    revs = []
    changeset = {}
    cmd = "#{GIT_BIN} --git-dir #{@git_path} log --reverse --raw --date=iso --all -- #{shell_quote(object)}"
    shell_cmd(cmd) do |line|
      if line =~ /^commit ([0-9a-f]{40})$/
        if(changeset.length == 4)
          revs << Revision.new(
            changeset[:commit][0..7],
            changeset[:commit],
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
        changeset[:commit][0..7],
        changeset[:commit],
        changeset[:author],
        changeset[:date],
        changeset[:message].strip
      )
    end
    revs
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

  def check_repository
    cmd = "#{GIT_BIN} --git-dir #{@git_path} status"
    output = ""
    shell_cmd(cmd) do |line|
      output += line
    end
    raise ProviderError.new 'Invalid git repository' if output.empty?
  end
  
end
