class AddPendingNotificationFieldToParticipant < ActiveRecord::Migration
  def self.up
    add_column :participants, :pending_notification, :boolean, :default => false
  end

  def self.down
    remove_column :participants, :pending_notification
  end
end
