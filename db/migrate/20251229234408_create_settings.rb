class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :company_name
      t.text :address
      t.string :email
      t.string :phone
      t.string :vat_id
      t.string :company_registration
      t.string :bank_name
      t.string :bank_account
      t.string :bank_swift

      t.timestamps
    end
  end
end
