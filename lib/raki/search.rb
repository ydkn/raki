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

require 'ferret'

module Raki
  class Search
    class << self
      
      include Ferret
      
      def init
        @index = Index::Index.new(:path => "#{Rails.root}/tmp/search.idx") if @index.nil?
      end
      
      def search(querystring)
        init
        results = []
        @index.search_each("content:\"#{querystring}\"") do |id, score|
          doc = @index[id]
          results << {:type => doc[:type], :page => doc[:page], :score => score}
        end
        results.sort {|a,b| a[:score] <=> b[:score]}
      end
      
      def <<(type, page, revision, content=nil, attachment=nil, date=Time.now)
        init
        if attachment.nil?
          @index << {:type => type, :page => page, :revision => revision, :date => date, :content => content}
        else
          @index << {:type => type, :page => page, :revision => revision, :date => date, :attachment => attachment}
        end
      end
      
      def refresh
        init
        Raki.initialized_providers.values.each do |provider|
          provider.types.each do |type|
            next unless Raki.provider(type) == provider
            Raki.provider(type).page_changes(type).each do |change|
              begin
                self.<< change.type, change.page, change.revision.id, Raki.provider(type).page_contents(change.type, change.page, change.revision.id), nil, change.revision.date
              rescue => e
              end
            end
            Raki.provider(type).attachment_changes(type).each do |att_change|
              begin
                self.<< att_change.type, att_change.page, change.revision.id, nil, att_change.attachment, change.revision.date
              rescue => e
              end
            end
          end
        end
      end
      
    end
  end
end
