class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.integer :participant_id
      t.integer :message_id

      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
