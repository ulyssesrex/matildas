class Artist < ApplicationRecord
  has_and_belongs_to_many :shows

  validates :name, :url, presence: true
end
