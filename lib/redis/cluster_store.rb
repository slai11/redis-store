require 'redis-clustering'
require 'redis/store/cluster_compat'
require 'redis/store/ttl'
require 'redis/store/interface'
require 'redis/store/namespace'
require 'redis/store/serialization'

class Redis
  class ClusterStore < ::Redis::Cluster
    include Redis::Store::Ttl, Redis::Store::Interface

    def initialize(options = {})
      orig_options = options.dup

      @serializer = orig_options.key?(:serializer) ? orig_options.delete(:serializer) : Marshal

      unless orig_options[:marshalling].nil?
        # `marshalling` only used here, might not be supported in `super`
        @serializer = orig_options.delete(:marshalling) ? Marshal : nil
      end

      _remove_unsupported_options(options)
      super(options)

      _extend_marshalling
      _extend_namespace orig_options
    end

    def inspect
      "Redis::ClusterStore #{}"
    end

    private

    def _remove_unsupported_options(options)
      # Unsupported keywords should be removed to avoid errors
      # https://github.com/redis-rb/redis-client/blob/v0.13.0/lib/redis_client/config.rb#L21
      options.delete(:raw)
      options.delete(:serializer)
      options.delete(:marshalling)
      options.delete(:namespace)
      options.delete(:scheme)
    end

    def _extend_marshalling
      extend Redis::Store::ClusterCompat.prepend(Redis::Store::Serialization) unless @serializer.nil?
    end

    def _extend_namespace(options)
      @namespace = options[:namespace]
      extend Redis::Store::ClusterCompat.prepend(Redis::Store::Namespace)
    end
  end
end