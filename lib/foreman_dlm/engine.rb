# frozen_string_literal: true

module ForemanDlm
  class Engine < ::Rails::Engine
    engine_name 'foreman_dlm'

    # Add any db migrations
    initializer 'foreman_dlm.load_app_instance_data' do |app|
      ForemanDlm::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_dlm.register_plugin', :before => :finisher_hook do |app|
      app.reloader.to_prepare do
        Foreman::Plugin.register :foreman_dlm do
          requires_foreman '>= 3.13'

          apipie_documented_controllers ["#{ForemanDlm::Engine.root}/app/controllers/api/v2/*.rb"]

          settings do
            category(:general) do
              setting('dlm_stale_time',
                type: :integer,
                default: 4,
                description: N_('Number of hours after which locked Distributed Lock is stale'),
                full_name: N_('Distributed Lock stale time'),
                validate: { numericality: { greater_than: 0 } })
            end
          end

          # Add permissions
          security_block :foreman_dlm do
            permission :view_dlmlocks, {
              :'foreman_dlm/dlmlocks' => [:index, :show, :auto_complete_search],
              :'api/v2/dlmlocks' => [:index, :show],
            }, :resource_type => 'ForemanDlm::Dlmlock'

            permission :create_dlmlocks, {
              :'api/v2/dlmlocks' => [:create],
            }, :resource_type => 'ForemanDlm::Dlmlock'

            permission :edit_dlmlocks, {
              :'foreman_dlm/dlmlocks' => [:release, :enable, :disable],
              :'api/v2/dlmlocks' => [:update, :acquire, :release],
            }, :resource_type => 'ForemanDlm::Dlmlock'

            permission :destroy_dlmlocks, {
              :'foreman_dlm/dlmlocks' => [:destroy],
              :'api/v2/dlmlocks' => [:destroy],
            }, :resource_type => 'ForemanDlm::Dlmlock'

            permission :view_dlmlock_events, {
              :'api/v2/dlmlock_events' => [:index],
            }, :resource_type => 'ForemanDlm::DlmlockEvent'
          end

          # Add a new role called 'Distributed Lock Manager' if it doesn't exist
          role 'Distributed Lock Manager', [:view_dlmlocks,
                                            :create_dlmlocks,
                                            :edit_dlmlocks,
                                            :destroy_dlmlocks,
                                            :view_dlmlock_events],
            'Role granting full access permissions to distributed locks'

          # add menu entry
          menu :top_menu, :foreman_dlm_dlmlocks,
            url_hash: { controller: :'foreman_dlm/dlmlocks', action: :index },
            caption: N_('Distributed Locks'),
            parent: :monitor_menu,
            after: :audits

          # Dlm Facet
          register_facet(ForemanDlm::DlmFacet, :dlm_facet) do
            api_view list: 'foreman_dlm/api/v2/dlm_facets/base_with_root', single: 'foreman_dlm/api/v2/dlm_facets/show'
          end

          register_custom_status HostStatus::DlmlockStatus

          # extend host show page
          extend_page('hosts/show') do |context|
            context.add_pagelet :main_tabs,
              :name => N_('Locks'),
              :partial => 'hosts/dlmlocks_tab',
              :onlyif => proc { |host| host.dlm_facet }
          end
        end
      end
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      Host::Managed.include ForemanDlm::HostExtensions
      User.include ForemanDlm::UserExtensions
      Host::Managed.include ForemanDlm::DlmFacetHostExtensions

      Host::Managed.include ForemanDlm::HostMonitoringExtensions if ForemanDlm.with_monitoring?
    rescue StandardError => e
      Rails.logger.warn "ForemanDlm: skipping engine hook (#{e})"
    end

    initializer 'foreman_dlm.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), 'locale')
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
