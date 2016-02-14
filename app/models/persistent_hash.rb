class PersistentHash < ActiveRecord::Base
  serialize :value, Hash

  validates :name, presence: true, uniqueness: true
end
