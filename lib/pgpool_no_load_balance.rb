require "pgpool_no_load_balance/active_record/querying"
require "pgpool_no_load_balance/active_record/relation/query_methods"
require "pgpool_no_load_balance/arel/select_manager"
require "pgpool_no_load_balance/active_record/connection_adapters/postgresql_adapter"
require "pgpool_no_load_balance/active_record/explain_subscriber"
require "pgpool_no_load_balance/railtie" if defined?(::Rails::Railtie)
require "pgpool_no_load_balance/version"

module PgpoolNoLoadBalance
  # Ordered: iteration order defines comment emission order (pgpool leads).
  COMMENTS = {
    pgpool: '/*NO LOAD BALANCE*/',
    pgdog:  '/* pgdog_role: primary */',
  }.freeze

  DEFAULT_BACKENDS = [:pgpool].freeze

  # Alias of the pgpool comment for any external reference. Internal code
  # resolves emitted comments via PgpoolNoLoadBalance.comment_prefix.
  NLB_COMMENT = COMMENTS[:pgpool]

  class PostgreSQLAdapterMissing < StandardError; end

  def self.backends
    @backends ||= DEFAULT_BACKENDS.dup
  end

  def self.backends=(value)
    names = Array(value)
            .flat_map { |v| v.is_a?(String) ? v.split(',') : v }
            .map { |v| v.to_s.strip.to_sym }
            .reject { |v| v == :"" }
            .uniq

    unknown = names - COMMENTS.keys
    unless unknown.empty?
      raise ArgumentError, "Unknown backend(s) #{unknown.inspect}. Valid backends: #{COMMENTS.keys.inspect}"
    end
    if names.empty?
      raise ArgumentError, "At least one backend is required. Valid backends: #{COMMENTS.keys.inspect}"
    end

    # Canonical order = COMMENTS key order (pgpool before pgdog).
    @backends = COMMENTS.keys.select { |k| names.include?(k) }
  end

  # Convenience singular setter.
  def self.backend=(value)
    self.backends = Array(value)
  end

  def self.comment_prefix
    backends.map { |b| COMMENTS.fetch(b) }.join(' ')
  end

  def self.force
    Thread.current[:pgpool_nlb_force] = true
    yield
  ensure
    Thread.current[:pgpool_nlb_force] = false
  end

  def self.force?
    !!Thread.current[:pgpool_nlb_force]
  end

  def self.setup!
    unless defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      raise PostgreSQLAdapterMissing, "No postgresql adapter specified by 'config/database.yml', or 'ActiveRecord::Base.establish_connection' method is not called."
    end
    ::ActiveRecord::Base.extend PgpoolNoLoadBalance::ActiveRecord::Querying
    ::ActiveRecord::Relation.prepend PgpoolNoLoadBalance::ActiveRecord::QueryMethods
    ::ActiveRecord::Relation::VALID_UNSCOPING_VALUES << :no_load_balance << :pgpool_nlb
    ::Arel::SelectManager.include PgpoolNoLoadBalance::Arel::SelectManager
    ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend PgpoolNoLoadBalance::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    ::ActiveRecord::ExplainSubscriber.prepend PgpoolNoLoadBalance::ActiveRecord::ExplainSubscriber
  end
end
