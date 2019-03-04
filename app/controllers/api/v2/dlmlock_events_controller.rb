module Api
  module V2
    class DlmlockEventsController < V2::BaseController
      include Api::Version2

      before_action :find_required_nested_object

      api :GET, '/dlmlocks/:dlmlock_id/dlmlock_events', N_('List all events for a given DLM lock')
      param :dlmlock_id, String, :desc => N_('ID of dlmlock')

      def index
        @events = resource_scope_for_index
      end

      def resource_class
        ForemanDlm::DlmlockEvent
      end

      private

      def action_permission
        case params[:action]
        when 'index'
          :view
        else
          super
        end
      end

      def allowed_nested_id
        ['dlmlock_id']
      end

      def resource_class_for(resource)
        return ForemanDlm::Dlmlock if resource == 'dlmlock'
        return ForemanDlm::DlmlockEvent if resource == 'dlmlock_event'
        super
      end
    end
  end
end
