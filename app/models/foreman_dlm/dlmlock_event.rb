module ForemanDlm
  class DlmlockEvent < ApplicationRecord
    include Authorizable

    TYPES = %w[release acquire enable disable failed].freeze
    validates :event_type, inclusion: { in: TYPES }

    def self.humanize_class_name
      N_('Distributed Lock Event')
    end

    belongs_to_host
    belongs_to :dlmlock, inverse_of: :dlmlock_events, class_name: 'ForemanDlm::Dlmlock'
    belongs_to :user, inverse_of: :dlmlock_events

    def humanized_type
      _('Dlmlock Event')
    end
  end
end
