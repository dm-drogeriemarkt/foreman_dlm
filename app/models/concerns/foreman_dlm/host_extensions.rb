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

    def can_acquire_update_locks?
      param = host_param('can_acquire_update_locks')
      return true if param.blank?

      Foreman::Cast.to_bool(param)
    end

    def refresh_dlmlock_status
      refresh_statuses([HostStatus::DlmlockStatus])
    end
  end
end
