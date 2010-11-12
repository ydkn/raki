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

module RecentchangesPluginHelper
  
  RIGHTS = [:view, :edit, :upload, :delete, :rename]
  
  def days_changes  
    days = {}
    
    @namespaces.each do |namespace|
      namespace = namespace.to_sym
      
      page_changes(namespace, @options).each do |change|
        next unless authorized? change.namespace, change.page, RIGHTS
        day = change.revision.date.strftime("%Y-%m-%d")
        days[day] = [] unless days.key?(day)
        days[day] << change
      end
      
      attachment_changes(namespace, nil, @options).each do |change|
        next unless authorized? change.namespace, change.page, RIGHTS
        day = change.revision.date.strftime("%Y-%m-%d")
        days[day] = [] unless days.key?(day)
        days[day] << change
      end
      
    end
    
    days.sort { |a,b| b <=> a }
  end
  
end
