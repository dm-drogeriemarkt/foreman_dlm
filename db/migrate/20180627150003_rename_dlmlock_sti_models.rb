# frozen_string_literal: true

class RenameDlmlockStiModels < ActiveRecord::Migration[5.1]
  def up
    execute "UPDATE dlmlocks set type='ForemanDlm::Dlmlock::Update' where type='Dlmlock::Update';"
  end

  def down
    execute "UPDATE dlmlocks set type='Dlmlock::Update' where type='ForemanDlm::Dlmlock::Update';"
  end
end
