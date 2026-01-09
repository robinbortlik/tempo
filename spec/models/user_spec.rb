require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to be_valid }

    describe "email_address" do
      it "is required" do
        user = build(:user, email_address: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to include("can't be blank")
      end

      it "must be unique" do
        create(:user, email_address: "test@example.com")
        user = build(:user, email_address: "test@example.com")
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to include("has already been taken")
      end

      it "is case-insensitive for uniqueness" do
        create(:user, email_address: "test@example.com")
        user = build(:user, email_address: "TEST@EXAMPLE.COM")
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to include("has already been taken")
      end

      it "must be a valid email format" do
        user = build(:user, email_address: "invalid-email")
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to include("must be a valid email address")
      end

      it "normalizes email to lowercase and strips whitespace" do
        user = create(:user, email_address: "  TEST@EXAMPLE.COM  ")
        expect(user.email_address).to eq("test@example.com")
      end
    end

    describe "password" do
      it "must be at least 8 characters" do
        user = build(:user, password: "short")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
      end

      it "accepts passwords of 8 characters or more" do
        user = build(:user, password: "12345678")
        expect(user).to be_valid
      end
    end
  end

  describe "associations" do
    it "has many sessions" do
      association = described_class.reflect_on_association(:sessions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "authentication" do
    let(:user) { create(:user, password: "password123") }

    it "authenticates with correct password" do
      expect(user.authenticate("password123")).to eq(user)
    end

    it "does not authenticate with incorrect password" do
      expect(user.authenticate("wrongpassword")).to be_falsey
    end
  end

  describe "locale" do
    it "accepts 'en' and 'cs' values and rejects invalid values" do
      user = build(:user, locale: "en")
      expect(user).to be_valid

      user.locale = "cs"
      expect(user).to be_valid

      user.locale = "de"
      expect(user).not_to be_valid
      expect(user.errors[:locale]).to include("is not included in the list")
    end
  end
end
