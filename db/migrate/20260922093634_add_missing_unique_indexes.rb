class AddMissingUniqueIndexes < ActiveRecord::Migration[8.1]
  def change
    # Company#name and Recruiter/Candidate#user_id were only unique per
    # Rails' `validates uniqueness: true` — enforced by a SELECT-then-INSERT
    # in Ruby, which has a real race window under concurrent requests.
    # Back them with real DB constraints.
    add_index :companies, :name, unique: true

    remove_index :recruiters, :user_id
    add_index :recruiters, :user_id, unique: true

    remove_index :candidates, :user_id
    add_index :candidates, :user_id, unique: true
  end
end
