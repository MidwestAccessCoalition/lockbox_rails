require 'rails_helper'

RSpec.describe 'Factories' do
  FactoryBot.factories.map(&:name).each do |factory_name|
    it "The :#{factory_name} factory makes valid models" do
      model = create(factory_name)
      expect(model).to be_valid
      expect(model).to be_persisted
    end
  end
end
