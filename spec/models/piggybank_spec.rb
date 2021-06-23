require 'rails_helper'

RSpec.describe Piggybank, type: :model do
  it { is_expected.to belong_to(:owner) }
end
