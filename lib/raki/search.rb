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

require 'fileutils'
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
        results.sort {|a,b| b[:score] <=> a[:score]}
      end
      
      def <<(namespace, page, revision, content=nil, attachment=nil)
        type = type.to_s
        page = page.to_s
        revision = revision.to_s
        doc_id = nil
        @index.search_each("(namespace:\"#{namespace}\" AND page:\"#{page}\" AND revision:\"#{revision}\")") {|id, score| doc_id = id}
        return false if doc_id
        if attachment
          doc = {:namespace => namespace, :page => page, :revision => revision, :attachment => attachment}
        else
          doc = {:namespace => namespace, :page => page, :revision => revision, :content => content}
        end
        @index << doc
        true
      end
      
      def indexed?(namespace, page, revision)
        doc_id = nil
        @index.search_each("(namespace:\"#{namespace}\" AND page:\"#{page}\" AND revision:\"#{revision}\")") {|id, score| doc_id = id}
        !doc_id.nil?
      end
      
      def refresh
        namespaces.each do |namespace|
          page_all(namespace).each do |page|
            page_revisions(namespace, page).reverse_each do |revision|
              next if indexed?(namespace, page, revision.id)
              begin
                self.<< namespace, page, revision.id, page_contents(namespace, page, revision.id), nil
              rescue => e
              end
            end
            attachment_all(namespace, page).each do |attachment|
              attachment_revisions(namespace, page, attachment).reverse_each do |revision|
                begin
                  self.<< namespace, page, revision.id, nil, attachment
                rescue => e
                end
              end
            end
          end
        end
        nil
      end
      
      def rebuild_index
        FileUtils.rm_rf(File.join(Rails.root, 'tmp', "#{Rails.env}.idx"))
        create_index
        refresh
      end
      
      def optimize_index
        @index.optimize
      end
      
      private
      
      def create_index
        @index = Ferret::Index::Index.new(:path => File.join(Rails.root, 'tmp', "#{Rails.env}.idx"))
        @index.field_infos.add_field(:namespace, :store => :yes, :boost => 5.0)
        @index.field_infos.add_field(:page, :store => :yes, :boost => 6.0)
        @index.field_infos.add_field(:attachment, :store => :yes, :boost => 5.0)
        @index.field_infos.add_field(:content, :store => :yes, :boost => 2.0)
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
              :namespace => doc[:namespace],
              :page => doc[:page],
              :attachment => doc[:attachment],
              :revision => doc[:revision],
              :score => score,
              :excerpt => @index.highlight(querystring, id, :field => :content, :pre_tag => '<b>', :post_tag => '</b>')
            }
        end
        
        results
      end
      
    end
    
    begin
      create_index
    rescue => e
      Rails.logger.error(e)
    end
    
  end
end
