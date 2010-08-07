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
    
    @index = Ferret::Index::Index.new(:path => "#{Rails.root}/tmp/search.idx")
    
    class << self
      
      include Raki::Helpers::PermissionHelper
      include Raki::Helpers::ProviderHelper
      
      def search(querystring)
        results = []
        # TODO build query
        @index.search_each(querystring) do |id, score|
          doc = @index[id]
          results << {
              :type => doc[:type],
              :page => doc[:page],
              :revision => doc[:revision],
              :score => score,
              :excerpt => @index.highlight(querystring, id, :field => :content, :pre_tag => '<b>', :post_tag => '</b>')
            }
        end
        results.sort {|a,b| a[:score] <=> b[:score]}
      end
      
      def <<(type, page, revision, content=nil, attachment=nil)
        type = type.to_s
        page = page.to_s
        revision = revision.to_s
        doc_id = nil
        @index.search_each("(type:\"#{type}\" AND page:\"#{page}\" AND revision:\"#{revision}\")") {|id, score| doc_id = id}
        @index.delete doc_id unless doc_id.nil?
        if attachment.nil?
          doc = {:type => type, :page => page, :revision => revision, :content => content}
        else
          doc = {:type => type, :page => page, :revision => revision, :attachment => attachment}
        end
        @index << doc
      end
      
      def refresh
        types.each do |type|
          page_all(type).each do |page|
            page_revisions(type, page).reverse_each do |revision|
              begin
                self.<< type, page, revision.id, page_contents(type, page, revision.id), nil
              rescue => e
              end
            end
            attachment_all(type, page).each do |attachment|
              attachment_revisions(type, page, attachment).reverse_each do |revision|
                begin
                  self.<< type, page, revision.id, nil, attachment
                rescue => e
                end
              end
            end
          end
        end
        nil
      end
      
    end
    
    Thread.new do
      refresh
    end
    
  end
end
