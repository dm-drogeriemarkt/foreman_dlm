# frozen_string_literal: true

class CreateDlmFacets < ActiveRecord::Migration[5.1]
  def change
    create_table :dlm_facets do |t|
      t.references :host, null: false, foreign_key: true, index: true, unique: true
      t.column :last_checkin_at, :datetime

      t.timestamps null: false
    end
  end
end
