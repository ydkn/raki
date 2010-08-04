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
  
  def days_changes
    p_types = params[:type].nil? ? [context[:type]] : params[:type].split(',')
    p_types = types if params[:type] == 'all'
    
    days = {}
    
    p_types.each do |type|
      type = type.to_sym
      
      page_changes(type).each do |change|
        day = change.revision.date.strftime("%Y-%m-%d")
        days[day] = [] unless days.key?(day)
        days[day] << change
      end
      
      attachment_changes(type).each do |change|
        day = change.revision.date.strftime("%Y-%m-%d")
        days[day] = [] unless days.key?(day)
        days[day] << change
      end
      
    end
    
    days.sort { |a,b| b <=> a }
  end
  
end
