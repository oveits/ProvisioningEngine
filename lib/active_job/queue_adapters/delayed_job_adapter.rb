module ActiveJob
  # Provides behavior for enqueuing and retrying jobs.
  module Enqueuing
    extend ActiveSupport::Concern

    # Includes the +perform_later+ method for job initialization.
    module ClassMethods
      # Push a job onto the queue. The arguments must be legal JSON types
      # (string, int, float, nil, true, false, hash or array) or
      # GlobalID::Identification instances. Arbitrary Ruby objects
      # are not supported.
      #
      # Returns an instance of the job class queued with arguments available in
      # Job#arguments.
#      def perform_later(*args)
#        #byebug
#        job_or_instantiate(*args).enqueue
#      end
#
#      protected
#        def job_or_instantiate(*args)
#          args.first.is_a?(self) ? args.first : new(*args)
#        end
    
    
      # Reschedules the job to be re-executed. This is useful in combination
      # with the +rescue_from+ option. When you rescue an exception from your job
      # you can ask Active Job to retry performing your job.
      #
      # ==== Options
      # * <tt>:wait</tt> - Enqueues the job with the specified delay
      # * <tt>:wait_until</tt> - Enqueues the job at the time specified
      # * <tt>:queue</tt> - Enqueues the job on the specified queue
      #
      # ==== Examples
      #
      #  class SiteScrapperJob < ActiveJob::Base
      #    rescue_from(ErrorLoadingSite) do
      #      retry_job queue: :low_priority
      #    end
      #
      #    def perform(*args)
      #      # raise ErrorLoadingSite if cannot scrape
      #    end
      #  end
#      def retry_job(options={})
#        enqueue options
#      end
      
      # Enqueues the job to be performed by the queue adapter.
      #
      # ==== Options
      # * <tt>:wait</tt> - Enqueues the job with the specified delay
      # * <tt>:wait_until</tt> - Enqueues the job at the time specified
      # * <tt>:queue</tt> - Enqueues the job on the specified queue
      #
      # ==== Examples
      #
      #    my_job_instance.enqueue
      #    my_job_instance.enqueue wait: 5.minutes
      #    my_job_instance.enqueue queue: :important
      #    my_job_instance.enqueue wait_until: Date.tomorrow.midnight
#      def enqueue(options={})
#        self.scheduled_at = options[:wait].seconds.from_now.to_f if options[:wait]
#        self.scheduled_at = options[:wait_until].to_f if options[:wait_until]
#        self.queue_name   = self.class.queue_name_from_part(options[:queue]) if options[:queue]
#        run_callbacks :enqueue do
#          if self.scheduled_at
#            self.class.queue_adapter.enqueue_at self, self.scheduled_at
#          else
#            self.class.queue_adapter.enqueue self
#          end
#        end
#        self
#      end

      # Dequeues the job to be performed by the queue adapter. Only supported for Delayed::Jobs yet.
      #
      # ==== Examples
      #
      #    my_job_instance.dequeue
      #
      #def dequeue(options={})
      def dequeue()
        run_callbacks :dequeue do
          self.class.queue_adapter.dequeue self
        end
        self
      end
      
      # returns a list of all instances of the class GeneralJob
      # inspired by: http://stackoverflow.com/questions/6365638/how-to-get-class-instances-in-ruby
      # 
      # ==== Examples
      #
      #    GeneralJob.all
      #
      def all
        listall = []
        ObjectSpace.each_object GeneralJob do |thisjob|
          listall << thisjob
        end
        listall
      end # end def all
    end # module ClassMethods
  end # module Enqueuing
  
  module Execution
    
    # is removing the backend job (e.g. Delayed::Job), if it exists and sets the proper status
    #
    # * *Args*    : none
    # * *Returns* :
    #   - +true+ -> the provider_job was found and removed successfully
    #   - +false+ -> provider_job was not found 
    # * *Raises* :
    #   - +ArgumentError+ -> if number of arguments is not 0
    #
    def cancel
      self.class.queue_adapter.dequeue self
    end 
  end # module ExecutionOld

  module Core
    # ID optionally provided by adapter
    attr_accessor :provider_job_id
  end
  
  module QueueAdapters
    class DelayedJobAdapter
      class << self
        def enqueue(job) #:nodoc:
          delayed_job = Delayed::Job.enqueue(JobWrapper.new(job.serialize), queue: job.queue_name)
          job.provider_job_id = delayed_job.id
          delayed_job
        end

        def enqueue_at(job, timestamp) #:nodoc:
          delayed_job = Delayed::Job.enqueue(JobWrapper.new(job.serialize), queue: job.queue_name, run_at: Time.at(timestamp))
          job.provider_job_id = delayed_job.id
          delayed_job
        end
        
        # is removing the backend job (e.g. Delayed::Job), if it exists and sets the proper status
        #
        # * *Args*    : none
        # * *Returns* :
        #   - +true+ -> the provider_job was found and removed successfully
        #   - +false+ -> provider_job was not found 
        # * *Raises* :
        #   - +ArgumentError+ -> if number of arguments is not 0
        #   - +Abort+ -> in case there were more than 1 delayed jobs found for this ActiveJob (points to a bug, if it happens)
        #
        def dequeue(job)
          provider_jobs = Delayed::Job.where(id: job.provider_job_id)
          case provider_jobs.count
          when 1
            provider_jobs[0].delete
            true
          when 0
            false
          else
            abort "There are more than one Delayed::Job.where(id: #{job.provider_job_id}). This should never happen and it looks like a bug."
          end
        end
      end

      class JobWrapper #:nodoc:
        attr_accessor :job_data

        def initialize(job_data)
          @job_data = job_data
        end

        def perform
          Base.execute(job_data)
        end
      end
    end
  end
end
