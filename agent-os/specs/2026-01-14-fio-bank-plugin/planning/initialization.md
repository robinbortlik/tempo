# Feature Initialization

## Spec Name
fio-bank-plugin

## Initial Description
Integration with FIO bank API using https://github.com/14113/fio_api gem. Follow the plugin development instructions in: docs/PLUGIN_DEVELOPMENT.md. The fio plugin will run everyday as cron job. That means, we need some orchestrator job, which will fetch all plugins and their configuration and based on there configuration automatically execute the sync at given time. The first functionality of this plugin will be to pull transactions and store them as incomes and expenses. It also try to match transaction reference with invoice reference and if it find such transaction with correct reference and amount it will mark the invoice as paid (we need a new state for that). We also need to be able to mark invoice as paid manually and we need to track when invoice was paid.

## Date Created
2026-01-14
