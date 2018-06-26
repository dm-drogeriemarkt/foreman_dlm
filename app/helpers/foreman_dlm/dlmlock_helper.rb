module ForemanDlm
  module DlmlockHelper
    def dlmlock_status_icon_class(lock)
      return 'ban' if lock.disabled?
      return 'lock' if lock.taken?
      'unlock'
    end

    def dlmlock_status_icon_color_class(lock)
      return 'text-danger' if lock.disabled?
      return 'text-success' if lock.taken?
      'text-info'
    end

    def dlmlock_actions(lock, authorizer)
      actions = []

      if lock.enabled?
        actions << display_link_if_authorized(
          _('Disable'),
          hash_for_disable_dlmlock_path(:id => lock.to_param).merge(auth_object: lock, authorizer: authorizer),
          method: :put
        )
      end

      if lock.disabled?
        actions << display_link_if_authorized(
          _('Enable'),
          hash_for_enable_dlmlock_path(:id => lock.to_param).merge(auth_object: lock, authorizer: authorizer),
          method: :put
        )
      end

      if lock.taken?
        actions << display_link_if_authorized(
          _('Release'),
          hash_for_release_dlmlock_path(:id => lock.to_param).merge(auth_object: lock, authorizer: authorizer),
          method: :put
        )
      end

      actions << display_delete_if_authorized(hash_for_dlmlock_path(:id => lock.to_param).merge(auth_object: lock, authorizer: authorizer), class: 'delete')
      actions
    end
  end
end
