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

class CreateReferences < ActiveRecord::Migration
  def self.up
    create_table :reference_targets do |t|
      t.string :namespace, :null => false
      t.string :name, :null => false
      t.string :filename, :null => true
      t.string :revision, :null => true
    end
    
    create_table :reference_links do |t|
      t.string :from_id, :null => false
      t.string :to_id, :null => false
    end
  end

  def self.down
    drop_table :reference_links
    drop_table :reference_targets
  end
end
