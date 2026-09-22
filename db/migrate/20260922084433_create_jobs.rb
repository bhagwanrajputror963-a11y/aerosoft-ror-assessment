class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.references :company, null: false, foreign_key: true
      t.references :recruiter, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :location
      t.integer :job_type
      t.string :category
      t.integer :salary_min
      t.integer :salary_max
      t.integer :status
      t.datetime :posted_at

      t.timestamps
    end
    add_index :jobs, :location
    add_index :jobs, :category
    add_index :jobs, :status
    add_index :jobs, :title
  end
end
