class Dlmlock < ApplicationRecord
  include Authorizable

  def self.humanize_class_name
    N_('Distributed Lock')
  end

  belongs_to_host
  audited

  validates :name, presence: true, uniqueness: true

  scoped_search :on => :name, :complete_value => true, :default_order => true
  scoped_search :relation => :host, :on => :name, :complete_value => true, :rename => :host
  scoped_search :on => :type, :complete_value => true, :default_order => true
  scoped_search :on => :enabled, :complete_value => { :true => true, :false => false }, :only_explicit => true

  attr_accessor :old

  def acquire!(host)
    atomic_update(nil, host)
  end

  def release!(host)
    atomic_update(host, nil)
  end

  def locked_by?(host)
    self.host == host
  end
  alias acquired_by? locked_by?

  def disabled?
    !enabled?
  end

  def locked?
    host.present?
  end
  alias taken? locked?

  def humanized_type
    _('Generic Lock')
  end

  private

  def atomic_update(old_host, new_host)
    changes = {
      host_id: new_host.try(:id)
    }
    self.old = dup
    num_updated = self.class.where(
      id: id,
      host_id: [new_host.try(:id), old_host.try(:id)],
      enabled: true
    ).update_all(changes.merge(updated_at: Time.now.utc))
    if num_updated > 0
      reload
      process_host_change(old_host, new_host, changes)
      return self
    end
    false
  end

  def process_host_change(old_host, new_host, changes)
    return if host.try(:id) == old.host.try(:id)
    write_audit(action: 'update', audited_changes: changes)
    run_callback(old_host, :unlock) if old.host
    run_callback(new_host, :lock) if host
  end

  def run_callback(h, callback)
    h.run_callbacks callback do
      logger.debug { "custom hook after_#{callback} on #{h} will be executed if defined." }
      true
    end
  end
end
