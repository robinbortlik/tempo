# FIO Bank Plugin - Raw Idea

## Feature Name
fio-bank-plugin

## Description
Integration with FIO bank API using the fio_api gem. This plugin will run as a daily cron job to pull transactions, store them as incomes/expenses, and automatically match transactions to invoices by reference and amount to mark them as paid.

## Key Capabilities
- Pull transactions from FIO bank API
- Store transactions as incomes/expenses
- Run as a daily cron job
- Automatically match transactions to invoices by reference and amount
- Mark matched invoices as paid

## Dependencies
- fio_api gem
