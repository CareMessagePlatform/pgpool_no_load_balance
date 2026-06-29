RSpec.describe PgpoolNoLoadBalance::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter do
  # Minimal stand-in for the real PostgreSQLAdapter. #execute echoes the SQL it
  # would send; #to_sql_and_binds returns the 4-tuple Rails 8 expects (the 4th
  # element is allow_retry). Prepending the gem module lets us assert the
  # comment-prepending behavior without a database.
  let(:adapter_class) do
    Class.new do
      def execute(sql, name = nil)
        sql
      end

      private

      def to_sql_and_binds(arel_or_sql_string, binds = [], preparable = nil, allow_retry = false)
        ["SELECT 1", binds, preparable, allow_retry]
      end
    end.tap { |klass| klass.prepend(described_class) }
  end

  let(:adapter) { adapter_class.new }

  after { PgpoolNoLoadBalance.backends = [:pgpool] }

  describe "#execute" do
    it "leaves the SQL untouched without the flag" do
      expect(adapter.execute("SELECT 1")).to eq("SELECT 1")
    end

    it "prepends the comment when no_load_balance is true" do
      expect(adapter.execute("SELECT 1", no_load_balance: true)).to eq("/*NO LOAD BALANCE*/ SELECT 1")
    end

    it "prepends the comment for the legacy pgpool_nlb keyword" do
      expect(adapter.execute("SELECT 1", pgpool_nlb: true)).to eq("/*NO LOAD BALANCE*/ SELECT 1")
    end

    it "prepends both comments when both backends are configured" do
      PgpoolNoLoadBalance.backends = [:pgpool, :pgdog]
      expect(adapter.execute("SELECT 1", no_load_balance: true))
        .to eq("/*NO LOAD BALANCE*/ /* pgdog_role: primary */ SELECT 1")
    end
  end

  describe "#to_sql_and_binds" do
    let(:flagged_arel)   { double(no_load_balance?: true) }
    let(:unflagged_arel) { double(no_load_balance?: false) }

    it "prepends the comment when the arel is flagged" do
      sql, = adapter.send(:to_sql_and_binds, flagged_arel)
      expect(sql).to eq("/*NO LOAD BALANCE*/ SELECT 1")
    end

    it "prepends the comment under force, even when unflagged" do
      sql = nil
      PgpoolNoLoadBalance.force { sql, = adapter.send(:to_sql_and_binds, unflagged_arel) }
      expect(sql).to eq("/*NO LOAD BALANCE*/ SELECT 1")
    end

    it "leaves the SQL untouched when not flagged and not forced" do
      sql, = adapter.send(:to_sql_and_binds, unflagged_arel)
      expect(sql).to eq("SELECT 1")
    end

    it "preserves the 4-element tuple including allow_retry" do
      result = adapter.send(:to_sql_and_binds, "SELECT 1", [], nil, true)
      expect(result.length).to eq(4)
      expect(result[3]).to be(true)
    end

    it "leaves plain string SQL untouched" do
      sql, = adapter.send(:to_sql_and_binds, "SELECT 1")
      expect(sql).to eq("SELECT 1")
    end
  end

  # Reproduces the real Rails 8 call path that double-prepended the comment:
  # ConnectionAdapters::QueryCache#select_all calls to_sql_and_binds(arel) to
  # build the cache key (yielding SQL *with* the comment), then hands that SQL
  # *string* to DatabaseStatements#select_all via super, which calls
  # to_sql_and_binds a second time. Rails passes a String straight through, so
  # the only thing deciding whether to prepend again is the gem. This stub
  # mirrors Rails: arel-like input compiles to "SELECT 1", String input passes
  # through unchanged.
  describe "double invocation across the two select_all layers" do
    let(:rails_like_adapter_class) do
      Class.new do
        private

        def to_sql_and_binds(arel_or_sql_string, binds = [], preparable = nil, allow_retry = false)
          sql = arel_or_sql_string.is_a?(String) ? arel_or_sql_string : "SELECT 1"
          [sql, binds, preparable, allow_retry]
        end
      end.tap { |klass| klass.prepend(described_class) }
    end

    let(:rails_like_adapter) { rails_like_adapter_class.new }
    let(:unflagged_arel)     { double(no_load_balance?: false) }
    let(:flagged_arel)       { double(no_load_balance?: true) }

    # Simulate QueryCache#select_all -> DatabaseStatements#select_all: compile
    # the arel, then re-run to_sql_and_binds on the resulting SQL string.
    def double_invoke(arel)
      sql1, = rails_like_adapter.send(:to_sql_and_binds, arel)
      sql2, = rails_like_adapter.send(:to_sql_and_binds, sql1)
      sql2
    end

    it "prepends the comment only once under force" do
      PgpoolNoLoadBalance.backends = [:pgpool, :pgdog]
      sql = nil
      PgpoolNoLoadBalance.force { sql = double_invoke(unflagged_arel) }
      expect(sql).to eq("/*NO LOAD BALANCE*/ /* pgdog_role: primary */ SELECT 1")
    end

    it "prepends the comment only once for a flagged arel" do
      PgpoolNoLoadBalance.backends = [:pgpool, :pgdog]
      sql = double_invoke(flagged_arel)
      expect(sql).to eq("/*NO LOAD BALANCE*/ /* pgdog_role: primary */ SELECT 1")
    end
  end
end
