# frozen_string_literal: true

module ForemanDlm
  module UpdateCheckinTime
    extend ActiveSupport::Concern

    module ClassMethods
      def update_host_checkin_time(actions)
        before_action(:only => actions) { update_detected_host_checkin_time }
      end
    end

    private

    # Updates the last_checkin timestamp of a user
    def update_detected_host_checkin_time
      return unless @detected_host

      facet = @detected_host.dlm_facet || @detected_host.build_dlm_facet
      facet.save unless facet.persisted?
      facet.touch(:last_checkin_at)
    end
  end
end
