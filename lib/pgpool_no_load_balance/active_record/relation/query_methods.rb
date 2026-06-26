module PgpoolNoLoadBalance
  module ActiveRecord
    module QueryMethods
      def no_load_balance(value = true)
        spawn.no_load_balance!(value)
      end

      def no_load_balance!(value = true)
        self.no_load_balance_value = value
        self
      end

      def no_load_balance_value
        @values.fetch(:no_load_balance, nil)
      end

      def no_load_balance_value=(value)
        @values[:no_load_balance] = value
      end

      alias_method :pgpool_nlb, :no_load_balance
      alias_method :pgpool_nlb!, :no_load_balance!
      alias_method :pgpool_nlb_value, :no_load_balance_value
      alias_method :pgpool_nlb_value=, :no_load_balance_value=

      # Accept the legacy :pgpool_nlb symbol as an alias for :no_load_balance
      # so unscope works regardless of which name set the scope.
      def unscope!(*args)
        args = args.map { |arg| arg == :pgpool_nlb ? :no_load_balance : arg }
        super(*args)
      end

      private

      def build_arel(...)
        arel = super(...)
        arel.no_load_balance(no_load_balance_value)
        arel
      end
    end
  end
end
