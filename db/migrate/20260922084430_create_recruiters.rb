class CreateRecruiters < ActiveRecord::Migration[8.1]
  def change
    create_table :recruiters do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :position

      t.timestamps
    end
  end
end
