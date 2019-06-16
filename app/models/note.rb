class Note < ApplicationRecord
  belongs_to :notable, polymorphic: true
  validates :text, presence: true
end
