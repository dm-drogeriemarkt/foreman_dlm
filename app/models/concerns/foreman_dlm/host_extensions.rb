module ForemanDlm
  module HostExtensions
    extend ActiveSupport::Concern

    included do
      has_many :dlmlocks,
               foreign_key: 'host_id',
               dependent: :nullify,
               inverse_of: :host

      define_model_callbacks :lock, :only => :after
      define_model_callbacks :unlock, :only => :after
    end
  end
end
