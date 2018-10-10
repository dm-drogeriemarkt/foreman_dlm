class Setting
  class Dlm < ::Setting
    def self.load_defaults
      return unless ActiveRecord::Base.connection.table_exists?('settings')
      return unless super

      Setting.transaction do
        [
          set('dlm_stale_time', N_('Number of hours after which locked Distributed Lock is stale'), 4, N_('Distributed Lock stale time'))
        ].compact.each { |s| Setting::General.create s.update(category: 'Setting::General') }
      end

      true
    end

    def self.humanized_category
      N_('Distributed Locks')
    end
  end
end
