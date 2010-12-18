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

class CreateLocks < ActiveRecord::Migration
  def self.up
    create_table :locks do |t|
      t.string :page_namespace
      t.string :page_name
      t.string :locked_by
      t.datetime :locked_at
      t.datetime :expires_at
    end
    
    add_index :locks, [:page_namespace, :page_name], :name => 'locks_page', :unique => true
  end

  def self.down
    drop_table :locks
  end
end
