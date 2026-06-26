RSpec.describe PgpoolNoLoadBalance::ActiveRecord::ExplainSubscriber do
  # Base #ignore_payload? records the SQL it receives so we can assert the
  # comment was stripped before delegation.
  let(:subscriber_class) do
    Class.new do
      attr_reader :seen_sql

      def ignore_payload?(payload)
        @seen_sql = payload[:sql]
        false
      end
    end.tap { |klass| klass.prepend(described_class) }
  end

  let(:subscriber) { subscriber_class.new }

  it "strips the pgpool comment before delegating" do
    subscriber.ignore_payload?(sql: "/*NO LOAD BALANCE*/ SELECT 1")
    expect(subscriber.seen_sql).to eq(" SELECT 1")
  end

  it "strips the pgdog comment before delegating" do
    subscriber.ignore_payload?(sql: "/* pgdog_role: primary */ SELECT 1")
    expect(subscriber.seen_sql).to eq(" SELECT 1")
  end

  it "strips both comments when both are present" do
    subscriber.ignore_payload?(sql: "/*NO LOAD BALANCE*/ /* pgdog_role: primary */ SELECT 1")
    expect(subscriber.seen_sql).to eq("  SELECT 1")
  end

  it "does not mutate the original payload" do
    payload = { sql: "/*NO LOAD BALANCE*/ SELECT 1" }
    subscriber.ignore_payload?(payload)
    expect(payload[:sql]).to eq("/*NO LOAD BALANCE*/ SELECT 1")
  end
end
