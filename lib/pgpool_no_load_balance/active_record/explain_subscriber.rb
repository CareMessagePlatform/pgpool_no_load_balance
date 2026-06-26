module PgpoolNoLoadBalance
  module ActiveRecord
    module ExplainSubscriber
      def ignore_payload?(payload)
        payload_for_check = payload.dup
        sql = payload_for_check[:sql]
        PgpoolNoLoadBalance::COMMENTS.each_value do |comment|
          sql = sql.sub(comment, '')
        end
        payload_for_check[:sql] = sql
        super payload_for_check
      end
    end
  end
end
