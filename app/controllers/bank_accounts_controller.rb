class BankAccountsController < ApplicationController
  before_action :set_bank_account, only: [ :update, :destroy ]

  def index
    render json: { bank_accounts: serialized_bank_accounts }
  end

  def create
    @bank_account = BankAccount.new(bank_account_params)

    if @bank_account.save
      render json: { bank_accounts: serialized_bank_accounts }
    else
      render json: { errors: errors_hash(@bank_account) }, status: :unprocessable_entity
    end
  end

  def update
    if @bank_account.update(bank_account_params)
      render json: { bank_accounts: serialized_bank_accounts }
    else
      render json: { errors: errors_hash(@bank_account) }, status: :unprocessable_entity
    end
  end

  def destroy
    result = DeletionValidator.can_delete_bank_account?(@bank_account)

    if result[:valid]
      @bank_account.destroy
      render json: { bank_accounts: serialized_bank_accounts }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def set_bank_account
    @bank_account = BankAccount.find(params[:id])
  end

  def bank_account_params
    params.require(:bank_account).permit(:name, :bank_name, :bank_account, :bank_swift, :iban, :is_default)
  end

  def serialized_bank_accounts
    BankAccountSerializer.new(BankAccount.order(:name)).serializable_hash
  end

  def errors_hash(record)
    record.errors.to_hash.transform_values { |messages| messages.first }
  end
end
