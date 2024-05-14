# frozen_string_literal: true

module ForemanDlm
  class Dlmlock < ApplicationRecord
    include Authorizable

    def self.humanize_class_name
      N_('Distributed Lock')
    end

    def self.dlm_stale_time
      (Setting[:dlm_stale_time] || 4).hours
    end

    belongs_to_host

    has_many :dlmlock_events,
      class_name: '::ForemanDlm::DlmlockEvent',
      dependent: :destroy,
      inverse_of: :dlmlock

    validates :name, presence: true, uniqueness: true

    after_save :log_enable_or_disable_event, if: -> { saved_change_to_enabled? }
    after_save :log_release_and_acquire_events, if: -> { saved_change_to_host_id? }

    def log_enable_or_disable_event
      event_type = enabled ? :enable : :disable
      log_event(host, event_type)
    end

    def log_release_and_acquire_events
      old_host_id = saved_changes[:host_id].first
      old_host = Host.find_by(id: old_host_id) if old_host_id
      log_event(old_host, :release) if old_host
      log_event(host, :acquire) if host
    end

    scope :locked,  -> { where.not(host_id: nil) }
    scope :stale,   -> { locked.where('updated_at < ?', Time.now.utc - dlm_stale_time) }

    scoped_search :on => :name, :complete_value => true, :default_order => true
    scoped_search :relation => :host, :on => :name, :complete_value => true, :rename => :host
    scoped_search :on => :type, :complete_value => true, :default_order => true
    scoped_search :on => :enabled, :complete_value => { :true => true, :false => false }, :only_explicit => true

    attr_accessor :old

    def acquire!(host)
      return false unless host.can_acquire_update_locks?

      result = atomic_update(nil, host)
      ForemanDlm::RefreshDlmlockStatus.set(wait: self.class.dlm_stale_time).perform_later([host.id]) if result
      result
    end

    def release!(host)
      atomic_update(host, nil)
    end

    def enable!
      update(enabled: true)
    end

    def disable!
      update(enabled: false)
    end

    def locked_by?(host)
      self.host == host
    end
    alias_method :acquired_by?, :locked_by?

    def disabled?
      !enabled?
    end

    def locked?
      host.present?
    end
    alias_method :taken?, :locked?

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
        enabled: true,
      }

      updated = self.class.where(query).update(changes.merge(updated_at: Time.now.utc))

      unless updated.count.zero?
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

      run_callback(old_host, :unlock) if old.host

      return unless host

      run_callback(new_host, :lock)
    end

    def log_event(host, event_type)
      DlmlockEvent.create!(
        dlmlock: self,
        event_type: event_type,
        host: host,
        user: User.current
      )
    end

    def run_callback(host, callback)
      host.run_callbacks callback do
        logger.debug { "custom hook after_#{callback} on #{host} will be executed if defined." }
        true
      end
    end
  end
end
