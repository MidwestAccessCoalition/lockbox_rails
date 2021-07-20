require 'rails_helper'

RSpec.describe PiggybankOrganization, type: :model do
  it { is_expected.to belong_to(:organization) }
  it { is_expected.to belong_to(:piggybank) }
end