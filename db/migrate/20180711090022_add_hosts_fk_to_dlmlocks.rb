class AddHostsFkToDlmlocks < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key :dlmlocks, :hosts
  end
end
