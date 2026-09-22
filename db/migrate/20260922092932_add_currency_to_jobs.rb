class AddCurrencyToJobs < ActiveRecord::Migration[8.1]
  def change
    # Default 0 = INR; existing rows (all India-based in seed data) backfill correctly.
    add_column :jobs, :currency, :integer, null: false, default: 0
  end
end
