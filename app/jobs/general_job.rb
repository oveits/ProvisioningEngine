class GeneralJob < ActiveJob::Base
  queue_as :default
  
  def setjobstatus(job, status)
    #
    # creates a Provisioning, if it does not exists
    # sets the status of the Provisioning
    object = job.arguments[0]
    if @provisioning.nil?
      object = job.arguments[0]
      @provisioning = Provisioning.new(action: "action=Synchronize Customer, CustomerName=#{Customer.name}", status: status, provisioningobject_type: object.class.name, provisioningobject_id: object.id)
      @provisioning.save!
    else
      @provisioning.update_attribute(:status, status)
    end
    
  end
  
  before_enqueue do |job|
    # Do something with the job instance
    setjobstatus(job, "enqueued")
  end

  around_perform do |job, block|
    # Do something before perform
    setjobstatus(job, "work in progress")
    
    # perform
    block.call
    
    # Do something after perform
    setjobstatus(job, "finished")
  end

  def perform(object, performmethod = method(:method))
    # Do something later
    if object.nil?
      call(performmethod)
    elsif object.is_a? Provisioningobject

      sleep 2.seconds
      returnvalue = object.send(performmethod)
      #abort returnvalue.class.name
      #abort returnvalue.inspect
       
    end
    
  end
end
