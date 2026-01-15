class MoneyTransactionFilterService
  def initialize(scope: MoneyTransaction.all, params: {})
    @scope = scope
    @params = params
  end

  def filter
    @scope = @scope.includes(:invoice).order(transacted_on: :desc, created_at: :desc)
    @scope = filter_by_period
    @scope = filter_by_transaction_type
    @scope = filter_by_description
    @scope
  end

  def available_years
    years_with_transactions = MoneyTransaction
      .distinct
      .pluck(Arel.sql("strftime('%Y', transacted_on)"))
      .map(&:to_i)

    (years_with_transactions + [Date.current.year]).uniq.sort.reverse
  end

  def year
    @year ||= (@params[:year] || Date.current.year).to_i
  end

  def month
    @month ||= @params[:month]&.to_i
  end

  def summary
    transactions = filter.to_a
    income_transactions = transactions.select(&:income?)
    expense_transactions = transactions.select(&:expense?)

    total_income = income_transactions.sum { |t| t.amount || 0 }
    total_expenses = expense_transactions.sum { |t| t.amount || 0 }

    {
      total_income: total_income.to_f,
      total_expenses: total_expenses.to_f,
      net_balance: (total_income - total_expenses).to_f,
      transaction_count: transactions.count
    }
  end

  private

  def filter_by_period
    @scope.for_period(period_start, period_end)
  end

  def period_start
    if month
      Date.new(year, month, 1)
    else
      Date.new(year, 1, 1)
    end
  end

  def period_end
    if month
      Date.new(year, month, 1).end_of_month
    else
      Date.new(year, 12, 31)
    end
  end

  def filter_by_transaction_type
    return @scope unless @params[:transaction_type].present?

    case @params[:transaction_type].to_s
    when "income"
      @scope.income
    when "expense"
      @scope.expenses
    else
      @scope
    end
  end

  def filter_by_description
    return @scope unless @params[:description].present?

    @scope.where("description LIKE ?", "%#{@params[:description]}%")
  end
end
