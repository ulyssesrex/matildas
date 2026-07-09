class Show < ApplicationRecord
  belongs_to :venue, optional: true

  has_and_belongs_to_many :links

  scope :unexpired, -> { where("time > ?", 2.weeks.ago) }
end
