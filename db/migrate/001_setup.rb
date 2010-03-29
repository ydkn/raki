class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :id => false do |t|
      t.string :username, :primary => true
      t.timestamp :last_login
      t.timestamp :created_at
    end
  end

  def self.down
    drop_table :users
  end
end
