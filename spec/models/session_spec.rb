require 'rails_helper'

RSpec.describe Session, type: :model do
  describe "associations" do
    it "belongs to user" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "factory" do
    it "creates a valid session" do
      user = create(:user)
      session = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Test Browser")
      expect(session).to be_persisted
    end
  end
end
