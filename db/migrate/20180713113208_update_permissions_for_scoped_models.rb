class UpdatePermissionsForScopedModels < ActiveRecord::Migration[5.1]
  class FakePermission < ApplicationRecord
    self.table_name = 'permissions'
  end

  def up
    FakePermission.where(resource_type: 'Dlmlock').update_all(resource_type: 'ForemanDlm::Dlmlock')
  end

  def down
    FakePermission.where(resource_type: 'ForemanDlm::Dlmlock').update_all(resource_type: 'Dlmlock')
  end
end
