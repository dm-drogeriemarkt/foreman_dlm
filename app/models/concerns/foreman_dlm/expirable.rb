# frozen_string_literal: true

module ForemanDlm
  module Expirable
    extend ActiveSupport::Concern

    module ClassMethods
      def expire(created_before:, batch_size:, sleep_time:)
        created_before ||= 1.week
        batch_size ||= 1000
        sleep_time ||= 0.2

        total_count = 0
        event_ids = []

        logger.info "Starting #{to_s.underscore.humanize.pluralize} expiration before #{created_before.ago} in batches of #{batch_size}"

        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        loop do
          event_ids = where(arel_table[:created_at].lt(created_before.ago)).reorder('').limit(batch_size).pluck(:id)

          count = where(id: event_ids).reorder('').delete_all

          total_count += count

          break if event_ids.blank?

          sleep sleep_time
        end
        duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) / 60).to_i

        logger.info "Total #{to_s.underscore.humanize.pluralize} expired: #{total_count}, duration: #{duration} min(s)"

        total_count
      end
    end
  end
end
