module Foreman::Controller::Parameters::Dlmlocks
  extend ActiveSupport::Concern

  class_methods do
    def dlmlocks_params_filter
      Foreman::ParameterFilter.new(::SshKey).tap do |filter|
        filter.permit :name, :type, :host_id, :enabled
      end
    end
  end

  def dlmlocks_params
    self.class.dlmlocks_params_filter.filter_params(params, parameter_filter_context)
  end
end
