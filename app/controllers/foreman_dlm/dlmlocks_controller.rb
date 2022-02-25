module ForemanDlm
  class DlmlocksController < ::ForemanDlm::ApplicationController
    include ::Foreman::Controller::AutoCompleteSearch

    before_action :setup_search_options, :only => :index
    before_action :find_resource, :only => [:show, :destroy, :release, :disable, :enable]

    def index
      @dlmlocks = resource_base_search_and_page(:host)
    end

    def show; end

    def destroy
      if @dlmlock.destroy
        process_success(
          :success_msg => _('Successfully deleted lock.'),
          :success_redirect => foreman_dlm_dlmlocks_path
        )
      else
        process_error
      end
    end

    def release
      if @dlmlock.update(host: nil)
        process_success(
          :success_msg => _('Successfully released lock.'),
          :success_redirect => foreman_dlm_dlmlocks_path
        )
      else
        process_error
      end
    end

    def disable
      if @dlmlock.disable!
        process_success(
          :success_msg => _('Successfully disabled lock.'),
          :success_redirect => foreman_dlm_dlmlocks_path
        )
      else
        process_error
      end
    end

    def enable
      if @dlmlock.enable!
        process_success(
          :success_msg => _('Successfully enabled lock.'),
          :success_redirect => foreman_dlm_dlmlocks_path
        )
      else
        process_error
      end
    end

    def model_of_controller
      ForemanDlm::Dlmlock
    end

    # see https://projects.theforeman.org/issues/25976
    # can be removed for Foreman 1.22+
    def auto_complete_controller_name
      current_version = Gem::Version.new(Foreman::Version.new.notag)
      return '/foreman_dlm/dlmlocks' if current_version >= Gem::Version.new('1.20') && current_version < Gem::Version.new('1.22')

      controller_name
    end

    private

    def action_permission
      case params[:action]
      when 'release', 'disable', 'enable'
        :edit
      else
        super
      end
    end
  end
end
