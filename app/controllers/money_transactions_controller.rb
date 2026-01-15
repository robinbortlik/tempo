class MoneyTransactionsController < ApplicationController
  def index
    filter_service = MoneyTransactionFilterService.new(params: filter_params)
    transactions = filter_service.filter

    render inertia: "MoneyTransactions/Index", props: {
      transactions: MoneyTransactionSerializer.new(transactions).serializable_hash,
      filters: current_filters,
      period: {
        year: filter_service.year,
        month: filter_service.month,
        available_years: filter_service.available_years
      },
      summary: filter_service.summary
    }
  end

  private

  def filter_params
    {
      year: params[:year],
      month: params[:month],
      transaction_type: params[:transaction_type],
      description: params[:description]
    }
  end

  def current_filters
    {
      year: filter_params[:year]&.to_i || Date.current.year,
      month: filter_params[:month]&.to_i,
      transaction_type: filter_params[:transaction_type],
      description: filter_params[:description]
    }
  end
end
