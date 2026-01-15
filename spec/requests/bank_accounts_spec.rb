require 'rails_helper'

RSpec.describe BankAccountsController, type: :request do
  before { sign_in }

  describe "GET /bank_accounts" do
    it "returns list of bank accounts as JSON" do
      account1 = create(:bank_account, :default, name: "Main EUR", iban: "DE89370400440532013000")
      account2 = create(:bank_account, name: "CZK Account", iban: "CZ6508000000192000145399")

      get bank_accounts_path, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['bank_accounts'].length).to eq(2)
      expect(json['bank_accounts'].map { |a| a['name'] }).to contain_exactly("Main EUR", "CZK Account")
    end
  end

  describe "POST /bank_accounts" do
    it "creates a new bank account with valid params" do
      expect {
        post bank_accounts_path, params: {
          bank_account: {
            name: "New Account",
            bank_name: "Test Bank",
            bank_account: "123456",
            bank_swift: "TESTBICX",
            iban: "DE89370400440532013000",
            is_default: false
          }
        }, as: :json
      }.to change(BankAccount, :count).by(1)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['bank_accounts'].last['name']).to eq("New Account")
    end

    it "returns errors for invalid params" do
      post bank_accounts_path, params: {
        bank_account: { name: "", iban: "invalid" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end
  end

  describe "PATCH /bank_accounts/:id" do
    it "updates the bank account" do
      account = create(:bank_account, :default, name: "Old Name")

      patch bank_account_path(account), params: {
        bank_account: { name: "New Name" }
      }, as: :json

      expect(response).to have_http_status(:success)
      expect(account.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /bank_accounts/:id" do
    it "deletes account when no clients reference it" do
      create(:bank_account, :default)
      account = create(:bank_account, name: "To Delete")

      expect {
        delete bank_account_path(account), as: :json
      }.to change(BankAccount, :count).by(-1)

      expect(response).to have_http_status(:success)
    end

    it "returns error when clients reference the account" do
      account = create(:bank_account, :default)
      create(:client, bank_account: account)

      delete bank_account_path(account), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to include("clients")
    end
  end

  describe "setting default account" do
    it "unsets previous default when setting new default" do
      old_default = create(:bank_account, :default)
      new_account = create(:bank_account, is_default: false)

      patch bank_account_path(new_account), params: {
        bank_account: { is_default: true }
      }, as: :json

      expect(old_default.reload.is_default).to eq(false)
      expect(new_account.reload.is_default).to eq(true)
    end
  end
end
