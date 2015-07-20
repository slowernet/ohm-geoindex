require "bundler/setup"
require "rake/testtask"

REDIS_PID = File.join(File.dirname(__FILE__), "test", "tmp", "redis.pid")
REDIS_LOG = File.join(File.dirname(__FILE__), "test", "tmp", "redis.log")
REDIS_PORT = ENV['REDIS_PORT'] || 7771

task :default => [:setup, :_test, :teardown]

desc "Start the Redis server"
task :setup do
  unless File.exists?(REDIS_PID)
    system "#{File.join(File.dirname(__FILE__), 'test', 'redis-server')} --port #{REDIS_PORT} --pidfile #{REDIS_PID} --logfile #{REDIS_LOG} --daemonize yes"
  end
end

desc "Stop the Redis server"
task :teardown do
  if File.exists?(REDIS_PID)
    system "kill #{File.read(REDIS_PID)}"
    File.delete(REDIS_PID)
  end
end

# wrap :test so that we can still teardown
task :_test do
  begin
    Rake::Task[:test].invoke
  rescue Exception => e
    puts e
  end
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  # t.verbose = true
  ENV["REDIS_URL"] = "redis://127.0.0.1:#{REDIS_PORT.to_s}/0"
end
