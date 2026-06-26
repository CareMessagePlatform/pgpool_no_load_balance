RSpec.describe PgpoolNoLoadBalance::ActiveRecord::QueryMethods do
  # Minimal stand-in for ActiveRecord::Relation exposing only what the gem uses.
  let(:relation_class) do
    Class.new do
      attr_accessor :arel_double

      def initialize(values = {})
        @values = values
      end

      def spawn
        copy = self.class.new(@values.dup)
        copy.arel_double = arel_double
        copy
      end

      # NOTE: real ActiveRecord::Relation in Rails 8 has NO `assert_mutability!`
      # method, so the stand-in must not define one either — otherwise the spec
      # masks a NoMethodError that real AR raises.

      def unscope!(*args)
        args.each do |scope|
          raise ArgumentError, "Unrecognized scoping: #{scope}" unless [:no_load_balance, :pgpool_nlb].include?(scope)
          @values.delete(scope)
        end
        self
      end

      def unscope(*args)
        spawn.unscope!(*args)
      end

      def build_arel(*)
        arel_double
      end
    end.tap { |klass| klass.prepend(described_class) }
  end

  let(:relation) { relation_class.new }

  describe "no_load_balance" do
    it "spawns a relation flagged true by default" do
      expect(relation.no_load_balance.no_load_balance_value).to be true
    end

    it "does not mutate the receiver" do
      relation.no_load_balance
      expect(relation.no_load_balance_value).to be_nil
    end

    it "accepts an explicit value" do
      expect(relation.no_load_balance(false).no_load_balance_value).to be false
    end
  end

  describe "no_load_balance!" do
    it "mutates the receiver in place and returns self" do
      expect(relation.no_load_balance!).to be(relation)
      expect(relation.no_load_balance_value).to be true
    end
  end

  describe "legacy pgpool_nlb aliases" do
    it "share storage with no_load_balance" do
      spawned = relation.pgpool_nlb
      expect(spawned.pgpool_nlb_value).to be true
      expect(spawned.no_load_balance_value).to be true
    end
  end

  describe "#unscope" do
    it "clears the value when unscoped by :no_load_balance" do
      flagged = relation.no_load_balance
      expect(flagged.unscope(:no_load_balance).no_load_balance_value).to be_nil
    end

    it "clears the value when unscoped by the legacy :pgpool_nlb symbol" do
      flagged = relation.no_load_balance
      expect(flagged.unscope(:pgpool_nlb).no_load_balance_value).to be_nil
    end
  end

  describe "#build_arel" do
    it "flags the arel with the stored value" do
      arel = double("arel")
      relation.arel_double = arel
      relation.no_load_balance!
      expect(arel).to receive(:no_load_balance).with(true)
      relation.send(:build_arel)
    end
  end
end
