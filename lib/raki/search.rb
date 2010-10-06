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
    
    SEARCH_FIELDS = [:page, :content, :attachment]
    
    class << self
      
      include Raki::Helpers::ProviderHelper
      
      def search(querystring)
        results = []
        SEARCH_FIELDS.each do |field|
          results += field_search field, querystring
        end
        results.sort {|a,b| a[:score] <=> b[:score]}
      end
      
      def field_search(field, querystring)
        query = Ferret::Search::MultiTermQuery.new(field.to_sym)
        querystring.downcase.split(/\s+/).each do |term|
          query.add_term(term) 
        end
        results = []
        @index.search_each(query) do |id, score|
          doc = @index[id]
          results << {
              :type => doc[:type],
              :page => doc[:page],
              :revision => doc[:revision],
              :attachment => doc[:attachment],
              :score => score,
              :excerpt => @index.highlight(querystring, id, :field => :content, :pre_tag => '<b>', :post_tag => '</b>')
            }
        end
        results.sort {|a,b| a[:score] <=> b[:score]}
        results.each do |r|
          p r
        end
        results
      end
      private :field_search
      
      def <<(type, page, revision, content=nil, attachment=nil)
        type = type.to_s
        page = page.to_s
        revision = revision.to_s
        doc_id = nil
        @index.search_each("(type:\"#{type}\" AND page:\"#{page}\" AND revision:\"#{revision}\")") {|id, score| doc_id = id}
        return false unless doc_id.nil?
        if attachment.nil?
          doc = {:type => type, :page => page, :revision => revision, :content => content}
        else
          doc = {:type => type, :page => page, :revision => revision, :attachment => attachment}
        end
        @index << doc
        true
      end
      
      def indexed?(type, page, revision)
        doc_id = nil
        @index.search_each("(type:\"#{type}\" AND page:\"#{page}\" AND revision:\"#{revision}\")") {|id, score| doc_id = id}
        !doc_id.nil?
      end
      
      def refresh
        types.each do |type|
          page_all(type).each do |page|
            page_revisions(type, page).reverse_each do |revision|
              next if indexed?(type, page, revision.id)
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
      
      def rebuild_index
        require 'fileutils'
        FileUtils.rm_rf "#{Rails.root}/tmp/search.idx"
        create_index
        refresh
      end
      
      def create_index
        @index = Ferret::Index::Index.new(:path => "#{Rails.root}/tmp/search.idx")
        @index.field_infos.add_field(:type, :store => :yes, :boost => 5.0)
        @index.field_infos.add_field(:page, :store => :yes, :boost => 5.0)
        @index.field_infos.add_field(:content, :store => :yes, :boost => 2.0)
      end
      private :create_index
      
      def optimize_index
        @index.optimize
      end
      
    end
    
    begin
      create_index
    rescue => e
    end
    
  end
end
