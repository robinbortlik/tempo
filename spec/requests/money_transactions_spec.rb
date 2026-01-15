require 'rails_helper'

RSpec.describe MoneyTransactionsController, type: :request do
  describe "GET /money_transactions" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response with correct Inertia props structure" do
        create(:money_transaction, :income, amount: 1000, transacted_on: Date.current)
        create(:money_transaction, :expense, amount: 300, transacted_on: Date.current)

        get money_transactions_path, headers: inertia_headers
        json = JSON.parse(response.body)

        expect(response).to have_http_status(:success)
        expect(json['props']).to include('transactions', 'filters', 'period', 'summary')
        expect(json['props']['transactions'].length).to eq(2)
        expect(json['props']['summary']['total_income'].to_f).to eq(1000.0)
        expect(json['props']['summary']['total_expenses'].to_f).to eq(300.0)
      end

      it "filters by transaction_type and description params" do
        income_tx = create(:money_transaction, :income, description: "Client payment", transacted_on: Date.current)
        create(:money_transaction, :expense, description: "Office rent", transacted_on: Date.current)

        get money_transactions_path(transaction_type: "income", description: "client"), headers: inertia_headers
        json = JSON.parse(response.body)

        transaction_ids = json['props']['transactions'].map { |t| t['id'] }
        expect(transaction_ids).to eq([income_tx.id])
      end

      it "filters by year and month params" do
        jan_tx = create(:money_transaction, transacted_on: Date.new(2026, 1, 15))
        create(:money_transaction, transacted_on: Date.new(2026, 2, 10))

        get money_transactions_path(year: 2026, month: 1), headers: inertia_headers
        json = JSON.parse(response.body)

        transaction_ids = json['props']['transactions'].map { |t| t['id'] }
        expect(transaction_ids).to eq([jan_tx.id])
        expect(json['props']['period']['year']).to eq(2026)
        expect(json['props']['period']['month']).to eq(1)
      end

      it "includes invoice_number when transaction is linked to invoice" do
        invoice = create(:invoice)
        create(:money_transaction, invoice: invoice, transacted_on: Date.current)

        get money_transactions_path, headers: inertia_headers
        json = JSON.parse(response.body)

        expect(json['props']['transactions'].first['invoice_number']).to eq(invoice.number)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get money_transactions_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  private

  def inertia_headers
    { 'X-Inertia' => 'true', 'X-Inertia-Version' => ViteRuby.digest }
  end
end
