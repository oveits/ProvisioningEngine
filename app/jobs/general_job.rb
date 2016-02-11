# allows to put any instance method into the queue for later performance
# automatically creates a Provisioning
#
# TODO: prio 1: create rspec tests
# TODO: prio 1: check that the right Provisioningobject reference is set in the Provisioning (is missing in the Provisionings index table! Bug?)
# TODO: prio 1: set the right attempts value (how? as callback from the called method? Not so good...)
#
# TODO: prio 2: move out all provisioning specifics into another class, e.g. ProvisioningJob < GeneralJob
# 
class GeneralJob < ActiveJob::Base
  queue_as :default
  
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
    success = super
    
    if success
      setjobstatus("canceled")
      true
    else
      setjobstatus("provider_job not found")
      false
    end
  end
  
  def job
    self
  end

  # creates a Provisioning, if it does not exists.
  # Sets or updates the status of the Provisioning to the input value
  #
  # * *Args*    : 
  #   - +status+ -> String with status information
  # * *Returns* :
  #   - +provisioning+ -> the created or updated Provisioning
  # * *Raises* :
  #   - +SaveError+ -> if the created Provisioning could not be saved successfully
  #
  # TODO: method name suggests, that a GeneralJob status is set. However, this is not the case
  #       instead, a Provisioning is created and its status is set.
  #       better 
  #         - move setjobstatus(status) function to a new class ProvisioningJob < GeneralJob
  #         - create a local attr_accessor :status that create a method that handles it (e.g. use the now free setjobstatus(status) method name
  # 
  #  
  def setjobstatus(status)

    provisionings = Provisioning.where(job_id: job_id)
    if provisionings.count == 1
      provisioning = provisionings[0] 
    else 
      provisioning = nil
    end
    
    if provisioning.nil?
      object = job.arguments[0]
      method = job.arguments[1]
      #provisioning = Provisioning.new(action: "action=Synchronize Customer, CustomerName=#{Customer.name}", status: status, provisioningobject_type: object.class.name, provisioningobject_id: object.id, job_id: job_id)
      provisioning = Provisioning.new(action: "method=#{method}, object=#{object.inspect}", status: status, provisioningobject_type: object.class.name, provisioningobject_id: object.id, job_id: job_id)
      #provisioning = Provisioning.new(action: job.inspect,  status: status, provisioningobject_type: object.class.name, provisioningobject_id: object.id, job_id: job_id)
      provisioning.save!
    else
      provisioning.update_attribute(:status, status)
    end
    provisioning
    
  end
  
  before_enqueue do |job|
    # Do something with the job instance
    setjobstatus("enqueued")
  end

  around_perform do |job, block|
    # Do something before perform
    setjobstatus("work in progress")
    
    debug = true
    
    if debug
      puts "PPPPPPPPPPP before perform PPPPPPPPPPPPPP"
      #puts "job_id = #{job_id}"
      puts "job = #{job.inspect}"
      puts "job.provider_job_id = #{job.provider_job_id}"
      puts "self.provider_job_id = #{self.provider_job_id}"
      #job.provider_job_id = 1
      #puts "provisionings = #{provisionings.inspect}"
      puts "PPPPPPPPPPPPPPPPPPPPPPPPP"
    end
    
    # perform
    block.call
    
    if debug
      puts "PPPPPPPPPPP after perform PPPPPPPPPPPPPP"
      #puts "job_id = #{job_id}"
      puts "job = #{job.inspect}"
      puts "job.provider_job_id = #{job.provider_job_id}"
      puts "self.provider_job_id = #{self.provider_job_id}"
      #job.provider_job_id = 1
      #puts "provisionings = #{provisionings.inspect}"
      puts "PPPPPPPPPPPPPPPPPPPPPPPPP"
    end
    
    # Do something after perform
    setjobstatus("finished")
  end

  def perform(object, performmethod = method(:method))
    # Do something later
#    if object.nil?
#      # call the object's self.method
#      call(performmethod)
#    elsif object.is_a? Provisioningobject
#      # call the object's method
      returnvalue = object.send(performmethod)
#      #puts self.inspect
      returnvalue
#    end
    
  end
end
