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
  class Permission
    
    class << self
      
      def load_permissions
        @permissions = YAML.load(File.read("#{Rails.root}/config/permissions.yml"))
        unless @permissions.key?(:OVERRIDE)
          @permissions[:OVERRIDE] = []
        end
        Rails.logger.info "Permissions loaded."
      end
      private :load_permissions

      def to?(type, page, action, user)
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
        
        perms += @permissions[:OVERRIDE]

        perm = false
        perms.each do |right|
          right = right.first
          next if "#{type.to_s}/#{page.to_s}".match("^#{right[0].gsub('*', '.*')}$").nil?
          rights = right[1].split(',')
          rights.map {|r| r.to_s.strip}
          perm = true if rights.include?('all')
          perm = false if rights.include?('!all')
          perm = true if rights.include?(action.to_s)
          perm = false if rights.include?("!#{action.to_s}")
        end

        perm
      end

      def add_override(type, page, rights)
        rights = [rights] unless rights.is_a?(Array)
        rights.map {|r| r.to_s.strip}
        @permissions[:OVERRIDE] << {"#{type.to_s}/#{page.to_s}" => rights.join(',')}
      end
      
    end
    
    load_permissions
    
  end
end
