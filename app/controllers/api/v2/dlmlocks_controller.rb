module Api
  module V2
    class DlmlocksController < V2::BaseController
      include Api::Version2
      include Foreman::Controller::Parameters::Dlmlocks
      include ::ForemanDlm::FindHostByClientCert
      include ::ForemanDlm::UpdateCheckinTime

      wrap_parameters ForemanDlm::Dlmlock, :include => dlmlocks_params_filter.accessible_attributes(parameter_filter_context)

      authorize_host_by_client_cert [:show, :release, :acquire]
      update_host_checkin_time [:show, :release, :acquire]

      before_action :find_resource, :only => [:show, :update, :destroy]
      before_action :find_resource_or_create, :only => [:release, :acquire]
      before_action :find_host, :only => [:release, :acquire]
      before_action :setup_search_options, :only => [:index]

      def_param_group :dlmlock do
        param :dlmlock, Hash, :required => true, :action_aware => true do
          param :name, String, :required => true, :desc => N_('Name')
          param :type, ['ForemanDlm::Dlmlock:Update'], :required => true, :desc => N_('Type, e.g. ForemanDlm::Dlmlock:Update')
          param :enabled, :bool, :desc => N_('Enable the lock')
        end
      end

      api :GET, '/dlmlocks/', N_('List all DLM locks')
      param_group :search_and_pagination, ::Api::V2::BaseController

      def index
        @dlmlocks = resource_scope_for_index
        @total = resource_scope_for_index.count
      end

      api :GET, '/dlmlocks/:id/', N_('Show a DLM lock')
      api :GET, '/dlmlocks/:id/lock', N_('Show a DLM lock')
      error 404, 'Lock could not be found.'
      param :id, String, :required => true, :desc => N_('Id or name of the DLM lock')

      def show; end

      api :POST, '/dlmlocks', N_('Create a DLM lock')
      param_group :dlmlock, :as => :create

      def create
        @dlmlock = ForemanDlm::Dlmlock.new(dlmlocks_params)
        process_response @dlmlock.save
      end

      api :PUT, '/dlmlocks/:id/', N_('Update a DLM lock')
      param :id, String, :required => true, :desc => N_('Id or name of the DLM lock')
      param_group :dlmlock

      def update
        process_response @dlmlock.update_attributes(dlmlocks_params)
      end

      api :DELETE, '/dlmlocks/:id/', N_('Delete a DLM lock')
      param :id, String, :required => true, :desc => N_('Id or name of the DLM lock')

      def destroy
        process_response @dlmlock.destroy
      end

      api :PUT, '/dlmlocks/:id/lock', N_('Acquire a DLM lock')
      param :id, String, :required => true, :desc => N_('Id or name of the DLM lock')
      error 200, 'Lock acquired successfully.'
      error 412, 'Lock could not be acquired.'
      description <<-DOCS
        == Acquire a lock
        This action acquires a lock.
        It fails, if the lock is currently taken by another host.

        == Authentication & Host Identification
        The host is authenticated via a client certificate and identified via the CN of that certificate.
        DOCS

      def acquire
        process_lock_response @dlmlock.acquire!(@host)
      end

      api :DELETE, '/dlmlocks/:id/lock', N_('Release a DLM lock')
      param :id, String, :required => true, :desc => N_('Id or name of the DLM lock')
      error 200, 'Lock released successfully.'
      error 412, 'Lock could not be released.'

      description <<-DOCS
        == Release a lock
         This action releases a lock.
         It fails, if the lock is currently taken by another host.

        == Authentication & Host Identification
         The host is authenticated via a client certificate and identified via the CN of that certificate.
        DOCS

      def release
        process_lock_response @dlmlock.release!(@host)
      end

      def resource_class
        ForemanDlm::Dlmlock
      end

      private

      def resource_finder(scope, id)
        super
      rescue ActiveRecord::RecordNotFound
        result = scope.find_by(:name => id)
        raise ActiveRecord::RecordNotFound unless result
        result
      end

      def find_resource_or_create
        find_resource
      rescue ActiveRecord::RecordNotFound
        @dlmlock = ForemanDlm::Dlmlock.create(:name => params[:id], :type => 'ForemanDlm::Dlmlock::Update')
      end

      def action_permission
        case params[:action]
        when 'release', 'acquire'
          :edit
        else
          super
        end
      end

      def find_host
        @host = detected_host
        unless @host
          logger.info 'Denying access because no host could be detected.'
          if User.current
            render_error 'access_denied',
                         :status => :forbidden,
                         :locals => {
                           :details => 'You need to authenticate with a valid client cert. The DN has to match a known host.'
                         }
          else
            render_error 'unauthorized',
                         :status => :unauthorized,
                         :locals => {
                           :user_login => get_client_cert_hostname
                         }
          end
        end
        true
      end

      def process_lock_response(condition, response = nil)
        if condition
          process_success response
        else
          process_lock_resource_error
        end
      end

      def process_lock_resource_error(options = {})
        resource = options[:resource] || get_resource(options[:message])

        if resource.respond_to?(:permission_failed?) && resource.permission_failed?
          deny_access
        else
          render_error 'precondition_failed', :status => :precondition_failed, :locals => {
            :message => 'Precondition failed. Lock is in invalid state for this operation.'
          }
        end
      end
    end
  end
end
