# Add timestamp in log and optionaly Fiber_id and Thread_id

class TimeStampedFormatter 

  def initialize(delegate)
    @delegate=delegate
    @with_fiber_id=Rails.my_config(:log_thread_ids)
    @with_thread_id=Rails.my_config(:log_fiber_ids)
    if Rails.my_config(:log_timestamp_format)
      @timestamp_format=Rails.my_config(:log_timestamp_format)
    else
      @timestamp_format="%FT%T.%9N%Z"
    end
  end

  # This method is invoked when a log event occurs
  def call(severity, timestamp, progname, msg)
    stamp=timestamp.strftime(@timestamp_format)
    stamp+="<Thread #{Thread.current.object_id}>" if @with_thread_id
    stamp+="[Fiber #{Fiber.current.object_id}]" if @with_fiber_id
    stamp+=' ' if stamp[-1] != ' '
    stamp+@delegate.call(severity,timestamp,progname,msg)
  end

  def log_fiber_id(do_it=true)
    @with_fiber_id=do_it
  end

  def method_missing(method, *args, &blk)
    @delegate.__send__(method, *args, &blk)
  end

  def respond_to?(message, incl_private=false)
    @delegate.respond_to?(message,incl_private)
  end
end

  
Rails.logger.formatter=TimeStampedFormatter.new(Rails.logger.formatter)
