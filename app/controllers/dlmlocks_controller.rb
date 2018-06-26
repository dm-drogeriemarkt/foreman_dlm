class DlmlocksController < ::ApplicationController
  include Foreman::Controller::AutoCompleteSearch

  before_action :setup_search_options, :only => :index
  before_action :find_resource, :only => [:show, :destroy]

  def index
    @dlmlocks = resource_base_search_and_page(:host)
  end

  def show; end

  def destroy
    if @dlmlock.destroy
      process_success(
        :success_msg => _('Successfully deleted lock.'),
        :success_redirect => dlmlocks_path
      )
    else
      process_error
    end
  end
end
