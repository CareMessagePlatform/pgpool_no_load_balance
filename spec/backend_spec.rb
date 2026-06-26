RSpec.describe "PgpoolNoLoadBalance backend configuration" do
  after { PgpoolNoLoadBalance.backends = [:pgpool] }

  it "defaults to the pgpool backend" do
    expect(PgpoolNoLoadBalance.backends).to eq([:pgpool])
  end

  it "emits only the pgpool comment by default" do
    expect(PgpoolNoLoadBalance.comment_prefix).to eq('/*NO LOAD BALANCE*/')
  end

  it "accepts a single symbol" do
    PgpoolNoLoadBalance.backends = :pgdog
    expect(PgpoolNoLoadBalance.backends).to eq([:pgdog])
    expect(PgpoolNoLoadBalance.comment_prefix).to eq('/* pgdog_role: primary */')
  end

  it "accepts an array and emits both comments, pgpool first" do
    PgpoolNoLoadBalance.backends = [:pgdog, :pgpool]
    expect(PgpoolNoLoadBalance.backends).to eq([:pgpool, :pgdog])
    expect(PgpoolNoLoadBalance.comment_prefix).to eq('/*NO LOAD BALANCE*/ /* pgdog_role: primary */')
  end

  it "accepts a comma-separated string" do
    PgpoolNoLoadBalance.backends = "pgpool, pgdog"
    expect(PgpoolNoLoadBalance.backends).to eq([:pgpool, :pgdog])
  end

  it "de-duplicates" do
    PgpoolNoLoadBalance.backends = [:pgpool, :pgpool]
    expect(PgpoolNoLoadBalance.backends).to eq([:pgpool])
  end

  it "supports the singular backend= alias" do
    PgpoolNoLoadBalance.backend = :pgdog
    expect(PgpoolNoLoadBalance.backends).to eq([:pgdog])
  end

  it "raises ArgumentError for an unknown backend" do
    expect { PgpoolNoLoadBalance.backends = :mysql }.to raise_error(ArgumentError, /Unknown backend/)
  end

  it "raises ArgumentError when empty" do
    expect { PgpoolNoLoadBalance.backends = [] }.to raise_error(ArgumentError)
  end
end
