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
  end

  def page_exists?(name, revision=nil)
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} ls-tree -l #{revision}:pages"
    shellcmd(cmd) do |line|
      if line.chomp.to_s =~ /^\d+\s+\w+\s+[0-9a-f]{40}\s+[0-9-]+\s+(.+)$/
        return true if $1 == name
      end
    end
    false
  end

  def page_contents(name, revision=nil)
    revision = 'HEAD' if revision.nil?
    cmd = "#{GIT_BIN} --git-dir #{@git_path} show #{revision}:pages/#{name}"
    contents = ""
    shellcmd(cmd) do |line|
      contents += line
    end
    contents
  end

  def page_revisions(name)
    revisions("pages/#{name}")
  end

  def save_page(name, contents, user, message)
    message = '-' if message.empty?
    File.open("#{@path}/pages/#{name}", 'w') do |f|
      f.write(contents)
    end
    cmd = "cd #{@path} && #{GIT_BIN} add pages/#{name}"
    shellcmd(cmd) do |line|
      #nothing
    end
    cmd = "cd #{@path} && #{GIT_BIN} commit -m \"#{message}\" --author=\"#{user.username} <#{user.email}>\" pages/#{name}"
    shellcmd(cmd) do |line|
      #nothing
    end
  end

  def page_rename(old_name, new_name)
  end

  private

  def revisions(object)
    commit_n = 0
    revs = []
    changeset = {}
    cmd = "#{GIT_BIN} --git-dir #{@git_path} log --reverse --raw --date=iso --all -- #{object}"
    shellcmd(cmd) do |line|
      if line =~ /^commit ([0-9a-f]{40})$/
        if(changeset.length == 4)
          revs << Revision.new(
            commit_n += 1,
            changeset[:commit],
            changeset[:author],
            changeset[:date],
            changeset[:message]
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
        commit_n += 1,
        changeset[:commit],
        changeset[:author],
        changeset[:date],
        changeset[:message]
      )
    end
    revs
  end

  def shellcmd(cmd, &block)
    IO.popen(cmd, "r+") do |io|
      io.close_write
      io.each_line do |line|
        block.call(line) if block_given?
      end
    end
  end
end
