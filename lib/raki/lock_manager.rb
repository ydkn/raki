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

module Raki
  class LockManager
    
    @locks = {}
    
    def self.lock(page, user)
      key = [page.namespace, page.name]
      @locks[key] = {:time => Time.new, :expires => (Time.new + 1800), :user => user} unless @locks.key? key
    end
    
    def self.locked?(page)
      key = [page.namespace, page.name]
      if @locks.key? key
        @locks[key][:expires] <= Time.new
      else
        false
      end
    end
    
    def self.locked_by(page)
      @locks[[page.namespace, page.name]][:user]
    end
    
    def self.unlock(page, user)
      key = [page.namespace, page.name]
      @locks.delete key if @locks[key][:user].id == user.id
    end
    
    Thread.new do
      while true do
        sleep(10)
        @locks.delete_if{|key, value| value[:expires] <= Time.new}
      end
    end
    
  end
end
