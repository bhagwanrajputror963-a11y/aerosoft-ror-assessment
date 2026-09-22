class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name
      t.text :description
      t.string :website
      t.string :location

      t.timestamps
    end
  end
end
