class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.integer :participant_id
      t.integer :chat_room_id
      t.boolean :active

      t.timestamps
    end
  end

  def self.down
    drop_table :memberships
  end
end
