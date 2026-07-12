class Show < ApplicationRecord
  belongs_to :venue, optional: true

  has_and_belongs_to_many :links

  scope :unexpired, -> { where(date: 2.weeks.ago.to_date..) }
  scope :chronological, -> { order(:date, Arel.sql("time IS NULL"), :time) }
end
