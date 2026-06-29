module PgpoolNoLoadBalance
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQLAdapter
        def execute(sql, name = nil, no_load_balance: false, pgpool_nlb: false)
          sql = prepend_comment(sql) if no_load_balance || pgpool_nlb
          super sql, name
        end

        private

        def to_sql_and_binds(arel_or_sql_string, binds = [], preparable = nil, allow_retry = false) # :nodoc:
          sql, binds, preparable, allow_retry = super
          if PgpoolNoLoadBalance.force? || (arel_or_sql_string.respond_to?(:no_load_balance?) && arel_or_sql_string.no_load_balance?)
            sql = prepend_comment(sql)
          end
          [sql.freeze, binds, preparable, allow_retry]
        end

        # Prepend the backend comment(s) once. A single logical query can reach
        # this method twice: ConnectionAdapters::QueryCache#select_all compiles
        # the arel to SQL (adding the comment), then hands that SQL string to
        # DatabaseStatements#select_all, which compiles it again. Under
        # PgpoolNoLoadBalance.force the thread-local stays true across both
        # calls, so without this guard the comment would be prepended twice.
        def prepend_comment(sql)
          prefix = PgpoolNoLoadBalance.comment_prefix
          return sql if sql.start_with?(prefix)
          "#{prefix} #{sql}"
        end
      end
    end
  end
end
