# frozen_string_literal: true

module ForemanDlm
  module HostMonitoringExtensions
    extend ActiveSupport::Concern

    included do
      after_lock :add_lock_monitoring_downtime
      after_unlock :remove_lock_monitoring_downtime
    end

    def add_lock_monitoring_downtime
      return unless monitored?

      logger.info "Setting Monitoring downtime for #{self}"
      monitoring.set_downtime_host(self, lock_monitoring_downtime_options)
      true
    rescue ProxyAPI::ProxyException => e
      Foreman::Logging.exception("Unable to set monitoring downtime for #{e}", e)
    end

    def remove_lock_monitoring_downtime
      return unless monitored?

      logger.info "Deleting Monitoring downtime for #{self}"
      monitoring.del_downtime_host(self, lock_monitoring_downtime_options)
      true
    rescue ProxyAPI::ProxyException => e
      Foreman::Logging.exception("Unable to remove monitoring downtime for #{e}", e)
    end

    def lock_monitoring_downtime_options
      {
        comment: _('Host acquired lock.'),
        start_time: Time.current.to_i,
        end_time: Time.current.advance(:minutes => 180).to_i,
      }
    end
  end
end
