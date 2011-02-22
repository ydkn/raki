# Raki - extensible rails-based wiki
# Copyright (C) 2011 Florian Schwab & Martin Sigloch
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
  class ReferenceManager
    
    class ReferenceTarget < ActiveRecord::Base
      has_many :from, :class_name => 'Raki::ReferenceManager::ReferenceLink', :foreign_key => 'from_id', :dependent => :destroy
      has_many :to, :class_name => 'Raki::ReferenceManager::ReferenceLink', :foreign_key => 'to_id', :dependent => :destroy
    end
    
    class ReferenceLink < ActiveRecord::Base
      belongs_to :from, :class_name => 'Raki::ReferenceManager::ReferenceTarget', :foreign_key => 'from_id'
      belongs_to :to, :class_name => 'Raki::ReferenceManager::ReferenceTarget', :foreign_key => 'to_id'
    end
    
    class << self
      
      def links_to(obj)
        ref_to = target_for(obj)
        
        pages = ReferenceLink.find_all_by_to_id(ref_to.id).collect do |ref|
          Page.new(:namespace => ref.from.namespace, :name => ref.from.name, :revision => ref.from.revision)
        end
        
        if obj.revision == obj.head_revision
          ref_to = target_for(obj, true)

          pages += ReferenceLink.find_all_by_to_id(ref_to.id).collect do |ref|
            Page.new(:namespace => ref.from.namespace, :name => ref.from.name, :revision => ref.from.revision)
          end
        end
        
        pages.uniq
      end
      
      def links_from(page)
        ref_from = target_for(page)
        
        ReferenceLink.find_all_by_from_id(ref_from.id).collect do |ref|
          Page.new(:namespace => ref.to.namespace, :name => ref.to.name, :revision => ref.to.revision)
        end
      end
      
      def update_all
        ActiveRecord::Base.transaction do
          targets = ReferenceTarget.all.collect{|t| t.id}
          refs = ReferenceLink.all.collect{|r| r.id}
          
          Page.changes.each do |r|
            ref_from = target_for(r.page)
            targets.delete(ref_from.id)
            
            r.page.links.each do |l|
              next if l.is_a?(String)
              
              ref_to = target_for(l)
              targets.delete(ref_to.id)
              
              ref = ReferenceLink.find_by_from_id_and_to_id(ref_from.id, ref_to.id)
              ref = ReferenceLink.create!({:from_id => ref_from.id, :to_id => ref_to.id}) unless ref
              refs.delete(ref.id)
            end
          end
          
          refs.each{|r| ReferenceLink.find(r).destroy}
          targets.each{|t| ReferenceTarget.find(t).destroy}
        end
      end
      
      private
      
      def target_for(obj, head_revision=false)
        if obj.is_a?(Attachment)
          namespace = obj.page.namespace.to_s
          page = obj.page.name.to_s
          filename = obj.name.to_s
        else
          namespace = obj.namespace.to_s
          page = obj.name.to_s
          filename = nil
        end
        
        revision = obj.revision.id rescue nil
        revision = nil if obj.link_to_head || head_revision
        
        ref_target = ReferenceTarget.find_by_namespace_and_name_and_filename_and_revision(namespace, page, filename, revision)
        ref_target = ReferenceTarget.create!({:namespace => namespace, :name => page, :filename => filename, :revision => revision}) unless ref_target
        
        ref_target
      end
      
    end
  end
end
