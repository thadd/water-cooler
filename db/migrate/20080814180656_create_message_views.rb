class CreateMessageViews < ActiveRecord::Migration
  def self.up
    create_table :message_views do |t|
      t.integer :participant_id, :message_id

      t.timestamps
    end
  end

  def self.down
    drop_table :message_views
  end
end
