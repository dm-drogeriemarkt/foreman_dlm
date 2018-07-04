module ForemanDlm
  module HostExtensions
    extend ActiveSupport::Concern

    included do
      has_many :dlmlocks,
               class_name: 'ForemanDlm::Dlmlock',
               foreign_key: 'host_id',
               dependent: :nullify,
               inverse_of: :host

      has_many :dlmlock_events,
               class_name: 'ForemanDlm::DlmlockEvent',
               foreign_key: 'host_id',
               dependent: :destroy,
               inverse_of: :host

      define_model_callbacks :lock, :only => :after
      define_model_callbacks :unlock, :only => :after
    end
  end
end
