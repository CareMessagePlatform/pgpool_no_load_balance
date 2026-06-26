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
end
