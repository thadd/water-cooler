class ChangeParticipantActiveToString < ActiveRecord::Migration
  def self.up
    remove_column :participants, :active
    add_column :participants, :active, :string
  end

  def self.down
    remove_column :participants, :active
    add_column :participants, :active, :boolean
  end
end
