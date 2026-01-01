# frozen_string_literal: true

module InvoicesHelper
  CURRENCY_SYMBOLS = {
    "EUR" => "\u20AC",
    "USD" => "$",
    "GBP" => "\u00A3",
    "CZK" => "Kč"
  }.freeze

  SYMBOL_AFTER_CURRENCIES = %w[CZK].freeze

  def format_currency(amount, currency, show_decimals: true)
    return "0" if amount.nil?

    symbol = CURRENCY_SYMBOLS[currency] || currency || ""
    precision = show_decimals ? 2 : 0
    formatted_amount = number_with_delimiter(number_with_precision(amount, precision: precision), delimiter: " ")
    symbol_after = SYMBOL_AFTER_CURRENCIES.include?(currency)

    if symbol_after
      "#{formatted_amount} #{symbol}"
    else
      "#{symbol}#{formatted_amount}"
    end
  end

  def format_rate(rate, currency)
    return "-" if rate.nil? || rate.zero?

    symbol = CURRENCY_SYMBOLS[currency] || currency || ""
    rounded_rate = rate.to_i
    symbol_after = SYMBOL_AFTER_CURRENCIES.include?(currency)

    if symbol_after
      "#{rounded_rate} #{symbol}/h"
    else
      "#{symbol}#{rounded_rate}/h"
    end
  end

  def format_hours(hours)
    return "0" if hours.nil?

    hours.to_i.to_s
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
