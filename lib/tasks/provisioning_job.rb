class ProvisioningJob < Struct.new(:provisioning_id)
  def perform
    provisioning = Provisioning.find(provisioning_id)
    provisioning.deliverbla
  end
end
