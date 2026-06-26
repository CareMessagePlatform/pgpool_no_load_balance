module PgpoolNoLoadBalance
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQLAdapter
        def execute(sql, name = nil, no_load_balance: false, pgpool_nlb: false)
          sql = "#{PgpoolNoLoadBalance.comment_prefix} #{sql}" if no_load_balance || pgpool_nlb
          super sql, name
        end

        private

        def to_sql_and_binds(arel_or_sql_string, binds = [], preparable = nil, allow_retry = false) # :nodoc:
          sql, binds, preparable, allow_retry = super
          if PgpoolNoLoadBalance.force? || (arel_or_sql_string.respond_to?(:no_load_balance?) && arel_or_sql_string.no_load_balance?)
            sql = "#{PgpoolNoLoadBalance.comment_prefix} #{sql}"
          end
          [sql.freeze, binds, preparable, allow_retry]
        end
      end
    end
  end
end
