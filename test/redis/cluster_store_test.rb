require 'test_helper'

describe "Redis::ClusterStore" do
  def setup
    @dmr = Redis::ClusterStore.new({ :nodes => [
      { :host => "localhost", :port => "7001", :db => 0 }
    ], :concurrency => { :model => :none } })
    @rabbit = OpenStruct.new :name => "bunny"
    @white_rabbit = OpenStruct.new :color => "white"
    @dmr.set "rabbit", @rabbit
  end

  def teardown
    @dmr.flushdb
  end

  it "sets an object" do
    @dmr.set "rabbit", @white_rabbit
    _(@dmr.get("rabbit")).must_equal(@white_rabbit)
  end

  it "sets an object with ttl" do
    @timeout = 3600
    @dmr.set "rabbit", @white_rabbit, { expire_after: @timeout }
    _(@dmr.ttl("rabbit")).must_equal(@timeout)
  end

  it "gets an object" do
    _(@dmr.get("rabbit")).must_equal(@rabbit)
  end

  it "mget" do
    @dmr.set "rabbit2", @white_rabbit
    @dmr.mget "rabbit", "rabbit2" do |rabbits|
      rabbit, rabbit2 = rabbits
      _(rabbits.length).must_equal(2)
      _(rabbit).must_equal(@rabbit)
      _(rabbit2).must_equal(@white_rabbit)
    end
  end

  it "mapped_mget" do
    @dmr.set "rabbit2", @white_rabbit
    result = @dmr.mapped_mget("rabbit", "rabbit2")
    _(result.keys).must_equal %w[ rabbit rabbit2 ]
    _(result["rabbit"]).must_equal @rabbit
    _(result["rabbit2"]).must_equal @white_rabbit
  end

  describe "namespace" do
    it "uses namespaced key" do
      @dmr = Redis::ClusterStore.new({ :nodes => [
        { :host => "localhost", :port => "7001", :db => 0 }
      ], :namespace => "theplaylist" })

      @dmr.set "rabbit", @white_rabbit
      _(@dmr.get("rabbit")).must_equal(@white_rabbit)

      @nodmr = Redis::ClusterStore.new({ :nodes => [
        { :host => "localhost", :port => "7001", :db => 0 }
      ] })

      _(@nodmr.get("theplaylist:rabbit")).must_equal(@white_rabbit)
    end
  end
end unless ENV['CI']
