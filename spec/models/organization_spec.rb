require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe "Relations" do
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:piggybanks).through(:piggybank_organizations) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:street_address) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:zip_code) }
    it { is_expected.to validate_presence_of(:phone_number) }
  end
end
