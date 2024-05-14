# frozen_string_literal: true

module ForemanDlm
  module FindHostByIp
    extend ActiveSupport::Concern

    module ClassMethods
      def authorize_host_by_ip(actions, _options = {})
        skip_before_action :require_login, :only => actions, :raise => false
        skip_before_action :authorize, :only => actions
        skip_before_action :verify_authenticity_token, :only => actions
        skip_before_action :set_taxonomy, :only => actions, :raise => false
        skip_before_action :session_expiry, :update_activity_time, :only => actions
        before_action(:only => actions) { require_ip_auth_or_login }
        attr_reader :detected_host
      end
    end

    private

    # Permits Hosts with an IP or a user with permission
    def require_ip_auth_or_login
      @detected_host = find_host_by_ip

      if detected_host
        set_admin_user
        return true
      end

      require_login
      unless User.current
        render_error 'access_denied', :status => :forbidden unless performed? && api_request?
        return false
      end
      authorize
    end

    def find_host_by_ip
      # try to find host based on our client ip address
      ip = ip_from_request_env

      # in case we got back multiple ips (see #1619)
      ip = ip.split(',').first

      # host is readonly because of association so we reload it if we find it
      host = Host.joins(:provision_interface).where(:nics => { :ip => ip }).first
      host = host ? Host.find(host.id) : nil
      logger.info { "Found Host #{host} by request IP #{ip}" } if host
      host
    end

    def ip_from_request_env
      request.env['REMOTE_ADDR']
    end
  end
end
