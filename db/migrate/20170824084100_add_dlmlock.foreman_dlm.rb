# frozen_string_literal: true

class AddDlmlock < ActiveRecord::Migration[4.2]
  def change
    create_table :dlmlocks do |t|
      t.string :name, null: false, unique: true
      t.string :type, index: true
      t.boolean :enabled, null: false, default: true, index: true
      t.integer :host_id, index: true

      t.timestamps
    end
  end
end
