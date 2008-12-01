class AddArchiveToChatRoom < ActiveRecord::Migration
  def self.up
    add_column :chat_rooms, :archived, :boolean, :default => false
  end

  def self.down
    remove_column :chat_rooms, :archived
  end
end
