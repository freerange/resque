require 'test_helper'
require 'resque/server/test_helper'

# Root path test
context "on GET to /" do
  setup { get "/" }

  test "redirect to overview" do
    follow_redirect!
  end
end

# Global overview
context "on GET to /overview" do
  setup { get "/overview" }

  test "should at least display 'queues'" do
    assert last_response.body.include?('Queues')
  end
end

# Working jobs
context "on GET to /working" do
  setup { get "/working" }

  should_respond_with_success
end

# Failed
context "on GET to /failed" do
  setup { get "/failed" }

  should_respond_with_success
end

# Stats 
context "on GET to /stats/resque" do
  setup { get "/stats/resque" }

  should_respond_with_success
end

context "on GET to /stats/redis" do
  setup { get "/stats/redis" }

  should_respond_with_success
end

context "on GET to /stats/resque" do
  setup { get "/stats/keys" }

  should_respond_with_success
end

# Status check
context "on GET to /check_queue_sizes with default max size of 100" do
  setup {
    7.times { Resque.enqueue(SomeIvarJob, 20, '/tmp') }
    get "/check_queue_sizes"
  }

  should_respond_with_success

  test "should show message that the queue sizes are ok" do
    assert_equal 'Queue sizes are ok.', last_response.body
  end
end

context "on GET to /check_queue_sizes with a lower max size" do
  setup {
    7.times { Resque.enqueue(SomeIvarJob, 20, '/tmp') }
    get "/check_queue_sizes?max_queue_size=5"
  }

  should_respond_with_success

  test "should show message that the queue is backing up" do
    assert_equal 'Queue size has grown larger than max queue size.', last_response.body
  end
end

context "on GET to /check_process_time" do
  setup do
    get "/check_process_time"
  end

  should_respond_with_success

  test "should show message that the queue worker is ok" do
    assert_equal 'No worker has been running for more than 600 seconds', last_response.body
  end
end

context "on GET to /check_process_time when a worker has been running for more than 10 minutes" do
  setup do
    @worker = Resque::Worker.new(:jobs)
    Resque::Job.create(:jobs, SomeJob, 20, '/tmp')

    @worker.work(0) do |job|
      data = @worker.encode \
        :queue   => job.queue,
        :run_at  => (Time.now - 601).to_s,
        :payload => job.payload
      @worker.redis.set("worker:#{@worker}", data)

      get "/check_process_time"
    end
  end

  should_respond_with_success

  test "should show message that the queue worker is not ok" do
    assert_equal 'A worker has been running for more than max_process_time', last_response.body
  end
end

context "on GET to /check_process_time providing a custom max_process_time" do
  setup do
    @worker = Resque::Worker.new(:jobs)
    Resque::Job.create(:jobs, SomeJob, 20, '/tmp')

    @worker.work(0) do |job|
      data = @worker.encode \
        :queue   => job.queue,
        :run_at  => (Time.now - 601).to_s,
        :payload => job.payload
      @worker.redis.set("worker:#{@worker}", data)

      get "/check_process_time?max_process_time=900"
    end
  end

  should_respond_with_success

  test "should show message that the queue worker is not ok" do
    assert_equal 'No worker has been running for more than 900 seconds', last_response.body
  end
end



