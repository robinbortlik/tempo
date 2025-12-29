class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.text :address
      t.string :email
      t.string :contact_person
      t.string :vat_id
      t.string :company_registration
      t.text :bank_details
      t.text :payment_terms
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.string :currency
      t.string :share_token, null: false

      t.timestamps
    end

    add_index :clients, :share_token, unique: true
  end
end
