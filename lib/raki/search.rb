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
      
      def search(querystring, options={})
        results = []
        SEARCH_FIELDS.each do |field|
          results += field_search(field, querystring)
        end
        results.delete_if{|r| !(r[:attachment] || r[:page]).authorized?(options[:user])} if options[:user]
        results.sort {|a,b| b[:score] <=> a[:score]}
      end
      
      def add(namespace, page, attachment, revision, content)
        return false if indexed?(namespace, page, attachment, revision)
        
        if attachment
          @index << {:namespace => namespace.to_s, :page => page.to_s, :attachment => attachment.to_s, :revision => revision.to_s, :content => content}
        else
          @index << {:namespace => namespace.to_s, :page => page.to_s, :revision => revision.to_s, :content => content}
        end
        
        true
      end
      
      def indexed?(namespace, page, attachment, revision)
        doc_id = nil
        
        query = "namespace:\"#{namespace.to_s}\" AND page:\"#{page.to_s}\" AND revision:\"#{revision.to_s}\""
        query += " AND attachment:\"#{attachment.to_s}\"" if attachment
        
        @index.search_each("(#{query})") {|id, score| doc_id = id}
        
        !doc_id.nil?
      end
      
      def refresh
        Page.all.each do |page| 
          add(page.namespace, page.name, nil, page.revision.id, page.content) unless indexed?(page.namespace, page.name, nil, page.revision.id)
          page.attachments.each do |attachment|
            add(attachment.page.namespace, attachment.page.name, attachment.name, attachment.revision.id, attachment.content) unless indexed?(attachment.page.namespace, attachment.page.name, attachment.name, attachment.revision.id)
          end
        end
        
        nil
      end
      
      def rebuild_index
        FileUtils.rm_rf(@index_file)
        create_index
        refresh
      end
      
      def optimize_index
        @index.optimize
      end
      
      private
      
      def create_index
        FileUtils.mkdir_p(File.dirname(@index_file)) unless File.exists?(@index_file)
        @index = Ferret::Index::Index.new(:path => @index_file)
        return if (@index.field_infos.fields - [:namespace, :revision, :content, :page, :attachment]).empty?
        @index.field_infos.add_field(:namespace, :store => :yes, :boost => 5.0)
        @index.field_infos.add_field(:page, :store => :yes, :boost => 6.0)
        @index.field_infos.add_field(:attachment, :store => :yes, :boost => 5.0)
        @index.field_infos.add_field(:content, :store => :yes, :boost => 2.0)
      end
      
      def field_search(field, querystring, options={})
        query = Ferret::Search::MultiTermQuery.new(field.to_sym)
        querystring.downcase.split(/\s+/).each do |term|
          query.add_term(term)
        end
        
        results = []
        @index.search_each(query) do |id, score|
          doc = @index[id]
          
          r = {
            :revision => doc[:revision],
            :score => score,
            :excerpt => @index.highlight(querystring, id, :field => :content, :pre_tag => '<b>', :post_tag => '</b>')
          }
          
          if doc[:attachment]
            r[:attachment] = Attachment.find(doc[:namespace], doc[:page], doc[:attachment], doc[:revision])
          else
            r[:page] = Page.find(doc[:namespace], doc[:page], doc[:revision])
          end
          
          results << r
        end
        
        results
      end
      
    end
    
    @index_file = File.join(Rails.root, 'tmp', 'search_index', "#{Rails.env}.idx")
    create_index
    
  end
end
