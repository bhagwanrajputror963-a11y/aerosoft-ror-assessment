class CreateApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :applications do |t|
      t.references :job, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.integer :status
      t.text :cover_letter
      t.datetime :applied_at

      t.timestamps
    end
    add_index :applications, [ :job_id, :candidate_id ], unique: true
  end
end
