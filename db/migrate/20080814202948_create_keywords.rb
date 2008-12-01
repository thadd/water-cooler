class CreateKeywords < ActiveRecord::Migration
  def self.up
    create_table :keywords do |t|
      t.string :text
      t.integer :participant_id

      t.timestamps
    end

    add_column :notifications, :keyword_id, :integer
  end

  def self.down
    drop_table :keywords
    remove_column :notifications, :keyword_id
  end
end
