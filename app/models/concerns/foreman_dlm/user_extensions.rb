module ForemanDlm
  module UserExtensions
    extend ActiveSupport::Concern

    included do
      has_many :dlmlock_events,
               class_name: 'ForemanDlm::DlmlockEvent',
               foreign_key: 'user_id',
               dependent: :nullify,
               inverse_of: :user
    end
  end
end
