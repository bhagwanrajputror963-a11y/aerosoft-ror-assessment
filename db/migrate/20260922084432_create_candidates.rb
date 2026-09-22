class CreateCandidates < ActiveRecord::Migration[8.1]
  def change
    create_table :candidates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :headline
      t.text :skills
      t.integer :experience_years
      t.string :resume_url

      t.timestamps
    end
  end
end
