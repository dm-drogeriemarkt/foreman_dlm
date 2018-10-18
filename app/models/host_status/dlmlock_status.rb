module HostStatus
  class DlmlockStatus < Status
    OK = 0
    STALE = 1

    def self.status_name
      N_('Distributed Lock')
    end

    def to_label(_options = {})
      case to_status
      when OK
        N_('Ok')
      when STALE
        N_('Stale')
      else
        N_('Unknown')
      end
    end

    def to_global(_options = {})
      case to_status
      when OK
        HostStatus::Global::OK
      else
        HostStatus::Global::ERROR
      end
    end

    def to_status(_options = {})
      ok? ? OK : STALE
    end

    def relevant?(_options = {})
      host.dlmlocks.any?
    end

    private

    def ok?
      host.dlmlocks.stale.empty?
    end
  end
end
