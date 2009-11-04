class UsersAddNameIsAdmin < ActiveRecord::Migration
  def self.up
		add_column :users, :name, :string
		add_column :users, :is_admin, :boolean, :null => false, :default => false
  end

  def self.down
		remove_column :users, :name
		remove_column :users, :is_admin
  end
end
