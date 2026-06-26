RSpec.describe PgpoolNoLoadBalance::ActiveRecord::Querying do
  let(:relation) { double("relation", no_load_balance: :nlb_relation, pgpool_nlb: :legacy_relation) }

  let(:model) do
    rel = relation
    Class.new do
      extend PgpoolNoLoadBalance::ActiveRecord::Querying
      define_singleton_method(:all) { rel }
    end
  end

  it "delegates no_load_balance to all" do
    expect(model.no_load_balance).to eq(:nlb_relation)
  end

  it "delegates the legacy pgpool_nlb to all" do
    expect(model.pgpool_nlb).to eq(:legacy_relation)
  end
end
