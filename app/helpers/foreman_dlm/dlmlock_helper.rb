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
  end
end
