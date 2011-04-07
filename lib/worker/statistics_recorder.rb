class Worker::StatisticsRecorder
  
  @queue = 'abacus_statistics'

  def self.perform(data)
    attributes = data.dup
    attributes['amount'] ||= 1
    puts "recording:#{attributes}"
    stat = Statistic.new(attributes)
    stat.increment_all!
    ActiveRecord::Base.connection_pool.clear_stale_cached_connections!
  end
  
end
