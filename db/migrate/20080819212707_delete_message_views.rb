class DeleteMessageViews < ActiveRecord::Migration
  def self.up
    drop_table :message_views
  end

  def self.down
    create_table :message_views do |t|
      t.integer :participant_id, :message_id

      t.timestamps
    end
  end
end
