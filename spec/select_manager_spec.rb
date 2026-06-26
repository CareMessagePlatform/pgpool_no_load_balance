RSpec.describe PgpoolNoLoadBalance::Arel::SelectManager do
  let(:manager) { Class.new { include PgpoolNoLoadBalance::Arel::SelectManager }.new }

  it "is not flagged by default" do
    expect(manager.no_load_balance?).to be_falsey
  end

  it "sets and reports the flag via no_load_balance" do
    manager.no_load_balance
    expect(manager.no_load_balance?).to be true
  end

  it "clears the flag when passed false" do
    manager.no_load_balance(false)
    expect(manager.no_load_balance?).to be false
  end

  it "returns self so it can be chained" do
    expect(manager.no_load_balance).to be(manager)
  end

  it "reports true inside a force block even when unflagged" do
    PgpoolNoLoadBalance.force { expect(manager.no_load_balance?).to be true }
  end

  it "exposes the legacy pgpool_nlb name sharing the same flag" do
    manager.pgpool_nlb
    expect(manager.pgpool_nlb?).to be true
    expect(manager.no_load_balance?).to be true
  end
end
