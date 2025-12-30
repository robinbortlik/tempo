# frozen_string_literal: true

module InvoicesHelper
  CURRENCY_SYMBOLS = {
    "EUR" => "\u20AC",
    "USD" => "$",
    "GBP" => "\u00A3",
    "CZK" => "K\u010D"
  }.freeze

  def format_currency(amount, currency)
    return "0.00" if amount.nil?

    symbol = CURRENCY_SYMBOLS[currency] || currency || ""
    formatted_amount = number_with_precision(amount, precision: 2, delimiter: ",")
    "#{symbol}#{formatted_amount}"
  end

  def format_period(period_start, period_end)
    return "Not specified" unless period_start && period_end

    start_month = period_start.strftime("%b")
    end_month = period_end.strftime("%b")
    start_day = period_start.day
    end_day = period_end.day
    year = period_end.year

    if start_month == end_month
      "#{start_month} #{start_day}\u2013#{end_day}, #{year}"
    else
      "#{start_month} #{start_day}\u2013#{end_month} #{end_day}, #{year}"
    end
  end
end
