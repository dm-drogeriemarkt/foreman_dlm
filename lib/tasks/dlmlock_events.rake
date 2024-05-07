# frozen_string_literal: true

desc <<-TASK_DESCRIPTION
 Expire lock events automatically

 Available conditions:
   * days        => number of days to keep reports (defaults to 14)
   * batch_size  => number of records deleted in single SQL transaction (defaults to 1k)
   * sleep_time  => delay in seconds between batches (defaults to 0.2)

TASK_DESCRIPTION

namespace :dlmlocks do
  task expire: :environment do
    created_before = ENV['days'].to_i.days if ENV['days']
    batch_size = ENV['batch_size'].to_i if ENV['batch_size']
    sleep_time = ENV['sleep_time'].to_f if ENV['sleep_time']

    ForemanDlm::DlmlockEvent.expire(created_before: created_before, batch_size: batch_size, sleep_time: sleep_time)
  end
end
