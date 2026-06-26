module PgpoolNoLoadBalance
  module Arel
    module SelectManager
      def no_load_balance(value = true)
        @no_load_balance_flag = !!value
        self
      end

      def no_load_balance?
        @no_load_balance_flag || PgpoolNoLoadBalance.force?
      end

      alias_method :pgpool_nlb, :no_load_balance
      alias_method :pgpool_nlb?, :no_load_balance?
    end
  end
end
