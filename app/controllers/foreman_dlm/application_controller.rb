module ForemanDlm
  class ApplicationController < ::ApplicationController
    def resource_class
      self.class.to_s.sub(/Controller$/, '').singularize.constantize
    end

    def resource_name(resource = resource_class)
      resource.name.split('::').last.downcase.singularize
    end

    def controller_name
      "foreman_dlm_#{super}"
    end
  end
end
