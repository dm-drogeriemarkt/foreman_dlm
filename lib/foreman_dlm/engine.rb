module ForemanDlm
  class Engine < ::Rails::Engine
    engine_name 'foreman_dlm'

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    # Add any db migrations
    initializer 'foreman_dlm.load_app_instance_data' do |app|
      ForemanDlm::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_dlm.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_dlm do
        requires_foreman '>= 1.17'

        apipie_documented_controllers ["#{ForemanDlm::Engine.root}/app/controllers/api/v2/*.rb"]

        # Add permissions
        security_block :foreman_dlm do
          permission :view_dlmlocks, {
            :dlmlocks => [:index, :show, :auto_complete_search],
            :'api/v2/dlmlocks' => [:index, :show]
          }, :resource_type => 'Dlmlock'

          permission :create_dlmlocks, {
            :'api/v2/dlmlocks' => [:create]
          }, :resource_type => 'Dlmlock'

          permission :edit_dlmlocks, {
            :dlmlocks => [:release, :enable, :disable],
            :'api/v2/dlmlocks' => [:update, :acquire, :release]
          }, :resource_type => 'Dlmlock'

          permission :destroy_dlmlocks, {
            :dlmlocks => [:destroy],
            :'api/v2/dlmlocks' => [:destroy]
          }, :resource_type => 'Dlmlock'
        end

        # Add a new role called 'Distributed Lock Manager' if it doesn't exist
        role 'Distributed Lock Manager', [:view_dlmlocks, :create_dlmlocks, :edit_dlmlocks, :destroy_dlmlocks]

        # add menu entry
        menu :top_menu, :distributed_locks,
             url_hash: { controller: :dlmlocks, action: :index },
             caption: N_('Distributed Locks'),
             parent: :monitor_menu,
             after: :audits
      end
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      begin
        Host::Managed.send(:include, ForemanDlm::HostExtensions)

        Host::Managed.send(:include, ForemanDlm::HostMonitoringExtensions) if ForemanDlm.with_monitoring?
      rescue StandardError => e
        Rails.logger.warn "ForemanDlm: skipping engine hook (#{e})"
      end
    end

    initializer 'foreman_dlm.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../../..', __FILE__), 'locale')
      locale_domain = 'foreman_dlm'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end

  def self.with_monitoring?
    ForemanMonitoring # rubocop:disable Lint/Void
    true
  rescue StandardError
    false
  end
end
