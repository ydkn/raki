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

class RecentchangesPluginHelper
  class << self
    include Raki::Helpers

    def build(params, body, context)
      days = {}
      provider_types.each do |type|
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
      days = days.sort { |a,b| b <=> a }
      out = ""
      days.each do |day,changes|
        out += "<tr><th>#{l(Time.parse(day), :format => :date)}</th><th></th><th></th><th></th></tr>"
        changes = changes.sort { |a,b| b.revision.date <=> a.revision.date }
        changes.each do |change|
          out += "<tr>"
          out += "<td><a href=\"#{url_for(:controller => 'page', :action => 'view', :type => change.type, :id => h(change.name), :revision => h(change.revision.id))}\">#{h(change.name)}</a></td>" if change.attachment.nil?
          out += "<td><a href=\"#{url_for(:controller => 'page', :action => 'attachment', :type => change.type, :id => h(change.name), :attachment => h(change.attachment), :revision => h(change.revision.id))}\">#{h(change.name+"/"+change.attachment)}</a></td>" unless change.attachment.nil?
          out += "<td>#{l(change.revision.date, :format => :time)}</td>"
          out += "<td><a href=\"#{url_for(:controller => 'page', :action => 'view', :type => :user, :id => h(change.revision.user))}\">#{h(change.revision.user)}</a></td>"
          out += "<td>#{h(change.revision.message)}</td>"
          out += "</tr>"
        end
      end
      "<table cellpadding=\"0\" cellspacing=\"0\" class=\"recentchanges\">#{out}</table>"
    end
    
    private
    
    def provider_types
      types = []
      Raki.providers.keys.each do |provider|
        types += Raki.provider(provider).types
      end
      types
    end

    def page_changes(type, limit=nil)
      return Raki.provider(type).page_changes(type, limit)
    end
    
    def attachment_changes(type, limit=nil)
      changes = []
      Raki.provider(type).page_all(type).each do |page|
        changes += Raki.provider(type).attachment_changes(type, page, limit)
      end
      changes
    end

  end
end
