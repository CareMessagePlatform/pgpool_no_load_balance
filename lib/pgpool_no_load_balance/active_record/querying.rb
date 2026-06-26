require "active_support"

module PgpoolNoLoadBalance
  module ActiveRecord
    module Querying
      delegate :no_load_balance, :pgpool_nlb, to: :all
    end
  end
end
