module ForemanDlm
  class Dlmlock < ApplicationRecord
    include Authorizable

    def self.humanize_class_name
      N_('Distributed Lock')
    end

    def self.dlm_stale_time
      (Setting::General[:dlm_stale_time] || 4).hours
    end

    belongs_to_host

    has_many :dlmlock_events,
             class_name: '::ForemanDlm::DlmlockEvent',
             foreign_key: 'dlmlock_id',
             dependent: :destroy,
             inverse_of: :dlmlock

    validates :name, presence: true, uniqueness: true

    scope :locked,  -> { where.not(host_id: nil) }
    scope :stale,   -> { locked.where('updated_at < ?', Time.now.utc - dlm_stale_time) }

    scoped_search :on => :name, :complete_value => true, :default_order => true
    scoped_search :relation => :host, :on => :name, :complete_value => true, :rename => :host
    scoped_search :on => :type, :complete_value => true, :default_order => true
    scoped_search :on => :enabled, :complete_value => { :true => true, :false => false }, :only_explicit => true

    attr_accessor :old

    def acquire!(host)
      result = atomic_update(nil, host)
      ForemanDlm::RefreshDlmlockStatus.set(wait: self.class.dlm_stale_time).perform_later([host.id]) if result
      result
    end

    def release!(host)
      atomic_update(host, nil)
    end

    def enable!
      return false unless update(enabled: true)

      log_event(host, :enable)

      true
    end

    def disable!
      return false unless update(enabled: false)

      log_event(host, :disable)

      true
    end

    def locked_by?(host)
      self.host == host
    end
    alias acquired_by? locked_by?

    def disabled?
      !enabled?
    end

    def locked?
      host.present?
    end
    alias taken? locked?

    def humanized_type
      _('Generic Lock')
    end

    private

    def atomic_update(old_host, new_host)
      changes = { host_id: new_host.try(:id) }
      self.old = dup

      query = {
        id: id,
        host_id: [new_host.try(:id), old_host.try(:id)],
        enabled: true
      }

      updated = self.class.where(query).update_all(changes.merge(updated_at: Time.now.utc))

      unless updated.zero?
        reload
        process_host_change(old_host, new_host)
        [old_host, new_host].compact.each(&:refresh_dlmlock_status)
        return true
      end

      log_event(host, :fail)

      false
    end

    def process_host_change(old_host, new_host)
      return if host.try(:id) == old.host.try(:id)

      if old.host
        log_event(old_host, :release)
        run_callback(old_host, :unlock)
      end

      return unless host

      log_event(new_host, :acquire)
      run_callback(new_host, :lock)
    end

    def log_event(host, event_type)
      DlmlockEvent.create(
        dlmlock: self,
        event_type: event_type,
        host: host,
        user: User.current
      )
    end

    def run_callback(h, callback)
      h.run_callbacks callback do
        logger.debug { "custom hook after_#{callback} on #{h} will be executed if defined." }
        true
      end
    end
  end
end
