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

class FileAuthorizer < Raki::AbstractAuthorizer
  
  def initialize
    @permissions = YAML.load(File.read("#{Rails.root}/config/permissions.yml"))
    Rails.logger.info "Permissions loaded."
  end
  
  def authorized_to?(namespace, page, action, user)
    perms = @permissions[:ALL]
    if user.is_a?(AnonymousUser)
      perms += @permissions[:ANONYMOUS]
    elsif user.is_a?(User)
      perms += @permissions[:AUTHENTICATED]
    end

    @permissions.each do |u_key, rights|
      next if u_key.is_a?(Symbol)
      next if user.id.match("^#{u_key}$").nil?
      perms += rights
    end

    perm = false
    perms.each do |right|
      right = right.first
      next if "#{namespace.to_s}/#{page.to_s}".match("^#{right[0].gsub('*', '.*')}$").nil?
      rights = right[1].split(',')
      rights.map {|r| r.to_s.strip}
      perm = true if rights.include?('all')
      perm = false if rights.include?('!all')
      perm = true if rights.include?(action.to_s)
      perm = false if rights.include?("!#{action.to_s}")
    end

    perm
  end
  
end