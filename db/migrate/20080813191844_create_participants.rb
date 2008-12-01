class CreateParticipants < ActiveRecord::Migration
  def self.up
    create_table :participants do |t|
      t.string :username, :unique => true, :null => false
      t.string :name
      t.boolean :active
      t.boolean :admin

      t.timestamps
    end
  end

  def self.down
    drop_table :participants
  end
end
