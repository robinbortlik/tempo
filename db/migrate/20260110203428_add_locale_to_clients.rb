class AddLocaleToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :locale, :string, default: "en", null: false
  end
end
