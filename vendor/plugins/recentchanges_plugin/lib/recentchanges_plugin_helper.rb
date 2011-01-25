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
    
    options = {:namespace => @namespaces}.merge @options
    
    Page.changes(options).select{|r| authorized? r.page}.each do |revision|
      day = revision.date.strftime "%Y-%m-%d"
      days[day] = [] unless days.key? day
      days[day] << revision
    end
    
    Attachment.changes(options).select{|r| authorized? r.page}.each do |revision|
      day = revision.date.strftime "%Y-%m-%d"
      days[day] = [] unless days.key? day
      days[day] << revision
    end
    
    days.keys.each do |day|
      days[day].sort!{|a,b| b <=> a}
    end
    days.sort {|a,b| b[0] <=> a[0] }
  end
  
  def authorized? page
    !RIGHTS.select{|r| page.authorized? User.current, r}.empty?
  end
  
  def short_title
    (@namespaces ? @namespaces.length : -1) == 1
  end
  
end
