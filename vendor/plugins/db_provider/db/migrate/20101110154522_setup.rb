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

class Setup < ActiveRecord::Migration
  
  def self.up
    create_table :pages do |t|
      t.string :namespace, :limit => 128, :null => false
      t.string :name, :limit => 128, :null => false
    end
    add_index :pages, [:namespace, :name], :name => 'pages_namespache_name', :unique => true
    
    create_table :page_revisions do |t|
      t.integer :page_id, :null => false
      t.integer :revision, :null => false, :default => 1
      t.string :author, :limit => 255, :null => false
      t.datetime :date, :null => false
      t.string :message, :limit => 255, :null => true
      t.text :content, :null => false
    end
    add_index :page_revisions, [:page_id, :revision], :name => 'page_revisions_page_revision', :unique => true
    
    create_table :attachments do |t|
      t.string :namespace, :limit => 128, :null => false
      t.string :page, :limit => 128, :null => false
      t.string :name, :limit => 128, :null => false
    end
    add_index :attachments, [:namespace, :page, :name], :name => 'pages_namespache_page_name', :unique => true
    
    create_table :attachment_revisions do |t|
      t.integer :attachment_id, :null => false
      t.integer :revision, :null => false, :default => 1
      t.string :author, :limit => 255, :null => false
      t.datetime :date, :null => false
      t.string :message, :limit => 255, :null => true
      t.binary :content, :null => false
    end
    add_index :attachment_revisions, [:attachment_id, :revision], :name => 'attachment_revisions_attachment_revision', :unique => true
    if ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/
      execute 'ALTER TABLE attachment_revisions MODIFY COLUMN content LONGBLOB'
    end
  end

  def self.down
    drop_table :pages
    drop_table :page_revisions
    drop_table :attachments
    drop_table :attachment_revisions
  end
  
end
