class CreateChatRooms < ActiveRecord::Migration
  def self.up
    create_table :chat_rooms do |t|
      t.string :name, :null => false
      t.boolean :locked, :default => false
      t.boolean :active, :default => true
      t.integer :owner_id

      t.timestamps
    end
  end

  def self.down
    drop_table :chat_rooms
  end
end
