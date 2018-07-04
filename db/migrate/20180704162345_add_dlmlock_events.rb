class AddDlmlockEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :dlmlock_events do |t|
      t.integer :dlmlock_id, index: true, null: false
      t.string :event_type, index: true
      t.integer :host_id, index: true
      t.integer :user_id
      t.timestamps
    end
  end
end
