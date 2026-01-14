# Mock bank API client for ExamplePlugin
# Simulates realistic bank API responses for development and testing
#
# Usage:
#   client = ExamplePlugin::MockBankApiClient.new(api_key: "test", account_id: "acc123")
#   client.account_info
#   # => { account_id: "acc123", account_name: "Business Account", currency: "EUR", balance: 15420.50 }
#
#   client.transactions(from_date: Date.current - 30, to_date: Date.current)
#   # => [{ id: "TXN001", ... }, ...]
#
class ExamplePlugin
  class MockBankApiClient
    MOCK_COUNTERPARTIES = [
      "Acme Corporation",
      "TechStart Inc.",
      "Global Services Ltd.",
      "Digital Solutions",
      "Creative Agency",
      "Consulting Partners",
      "Software Systems",
      "Innovation Labs"
    ].freeze

    MOCK_DESCRIPTIONS = [
      "Invoice payment",
      "Consulting services",
      "Project milestone",
      "Monthly retainer",
      "Development work",
      "Design services",
      "Support contract",
      "License renewal"
    ].freeze

    MOCK_EXPENSE_COUNTERPARTIES = [
      "Office Supplies Co",
      "Cloud Services Inc",
      "Domain Registrar",
      "Software License Ltd",
      "Coworking Space",
      "Internet Provider"
    ].freeze

    MOCK_EXPENSE_DESCRIPTIONS = [
      "Office supplies",
      "Cloud hosting",
      "Domain renewal",
      "Software subscription",
      "Workspace rental",
      "Internet service"
    ].freeze

    attr_reader :api_key, :account_id

    def initialize(api_key:, account_id: nil)
      @api_key = api_key
      @account_id = account_id || "MOCK_#{api_key[0..7]}"
    end

    # Validate credentials by checking API key format
    # @return [Boolean] true if credentials appear valid
    def valid_credentials?
      api_key.present? && api_key.length >= 8
    end

    # Get account information
    # @return [Hash] account details
    def account_info
      {
        account_id: account_id,
        account_name: "Business Account",
        currency: "EUR",
        balance: rand(5000.0..50000.0).round(2),
        iban: "CZ65 0800 0000 1920 0014 5399"
      }
    end

    # Fetch transactions within a date range
    # @param from_date [Date] start date
    # @param to_date [Date] end date (defaults to today)
    # @param limit [Integer] maximum transactions to return
    # @return [Array<Hash>] transaction records
    def transactions(from_date:, to_date: Date.current, limit: 100)
      # Generate deterministic but varied transactions based on date range
      all_transactions = generate_transactions(from_date, to_date)
      all_transactions.first(limit)
    end

    private

    # Generate mock transactions for a date range
    # Uses date-based seeding for deterministic results (same dates = same transactions)
    def generate_transactions(from_date, to_date)
      transactions = []
      current_date = from_date

      while current_date <= to_date
        # Seed random with date for deterministic results
        day_seed = current_date.to_s.hash.abs
        day_random = Random.new(day_seed)

        # Generate 0-3 transactions per day
        num_transactions = day_random.rand(0..3)

        num_transactions.times do |i|
          transactions << generate_transaction(current_date, i, day_random)
        end

        current_date += 1.day
      end

      transactions.sort_by { |t| t[:date] }.reverse
    end

    def generate_transaction(date, index, random)
      # 70% income, 30% expense
      is_income = random.rand < 0.7
      transaction_id = "TXN_#{date.strftime('%Y%m%d')}_#{format('%03d', index)}"

      if is_income
        {
          id: transaction_id,
          date: date,
          amount: (random.rand(500.0..5000.0) * 100).round / 100.0,
          currency: "EUR",
          counterparty: MOCK_COUNTERPARTIES[random.rand(MOCK_COUNTERPARTIES.length)],
          description: MOCK_DESCRIPTIONS[random.rand(MOCK_DESCRIPTIONS.length)],
          reference: "REF-#{date.strftime('%Y%m')}-#{random.rand(1000..9999)}",
          type: "credit"
        }
      else
        {
          id: transaction_id,
          date: date,
          amount: (random.rand(50.0..500.0) * 100).round / 100.0,
          currency: "EUR",
          counterparty: MOCK_EXPENSE_COUNTERPARTIES[random.rand(MOCK_EXPENSE_COUNTERPARTIES.length)],
          description: MOCK_EXPENSE_DESCRIPTIONS[random.rand(MOCK_EXPENSE_DESCRIPTIONS.length)],
          reference: "EXP-#{date.strftime('%Y%m')}-#{random.rand(1000..9999)}",
          type: "debit"
        }
      end
    end
  end
end
