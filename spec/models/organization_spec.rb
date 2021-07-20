require 'rails_helper'

RSpec.describe Organization, type: :model do
  it { is_expected.to have_many(:users) }
  it { is_expected.to have_many(:piggybanks).through(:piggybank_organizations) }
end
