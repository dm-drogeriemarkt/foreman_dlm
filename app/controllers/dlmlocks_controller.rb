class DlmlocksController < ::ApplicationController
  include Foreman::Controller::AutoCompleteSearch

  before_action :setup_search_options, :only => :index
  before_action :find_resource, :only => [:show]

  def index
    @dlmlocks = resource_base_search_and_page(:host)
  end

  def show; end
end
