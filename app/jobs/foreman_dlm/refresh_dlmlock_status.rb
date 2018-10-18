module ForemanDlm
  class RefreshDlmlockStatus < ApplicationJob
    queue_as :refresh_dlmlock_status_queue

    def perform(host_ids)
      Host::Managed.where(id: host_ids).each(&:refresh_dlmlock_status)
    end

    rescue_from(StandardError) do |error|
      Foreman::Logging.exception("Failed to refresh Distributed Lock status", error, logger: 'background')
    end

    def humanized_name
      _('Refresh Distributed Lock status')
    end
  end
end
