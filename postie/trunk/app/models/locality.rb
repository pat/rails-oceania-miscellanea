class Locality < ActiveRecord::Base
  validates_presence_of :postcode, :suburb, :state
  
  validates_length_of :postcode, :maximum => 4
  validates_length_of :state,    :maximum => 3
end