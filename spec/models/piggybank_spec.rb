require 'rails_helper'

RSpec.describe Piggybank, type: :model do
  it { is_expected.to have_many(:organizations).through(:piggybank_organizations) }

  it 'sets the default min acceptable balance' do
    piggy = Piggybank.new
    expect(piggy.minimum_acceptable_balance_cents).to eq(Piggybank::MINIMUM_ACCEPTABLE_BALANCE.cents)
  end
end
