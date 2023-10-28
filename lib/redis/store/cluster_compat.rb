class Redis
  class Store < self
    module ClusterCompat

      # As mget is not cross-slot compatible, we intercept the call
      # to convert it into a pipeline of gets.
      # There is no `super` call as it does not exists
      #
      def mget(*keys, &blk)
        puts 'cp1'
        reply = self.pipelined do |pipeline|
          keys.map { |k| pipeline.get(k) }
        end

        blk ? blk.call(reply) : reply
      end

      # todo, set will need args
      # lacks namespace support for mset
      def mset(*args)
        self.pipelined do |pipeline|
          args.each_slice(2) do |k, v|
            pipeline.set(k, v)
          end
        end
      end
    end
  end
end
