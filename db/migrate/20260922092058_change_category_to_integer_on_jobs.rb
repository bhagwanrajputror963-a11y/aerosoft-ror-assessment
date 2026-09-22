class ChangeCategoryToIntegerOnJobs < ActiveRecord::Migration[8.1]
  CATEGORIES = { "Pilot" => 0, "Cabin Crew" => 1, "AME" => 2, "MBA" => 3, "Ground Staff" => 4 }.freeze

  def up
    add_column :jobs, :category_enum, :integer
    CATEGORIES.each do |label, value|
      execute "UPDATE jobs SET category_enum = #{value} WHERE category = #{quote(label)}"
    end
    remove_column :jobs, :category
    rename_column :jobs, :category_enum, :category
    add_index :jobs, :category
  end

  def down
    add_column :jobs, :category_str, :string
    CATEGORIES.each do |label, value|
      execute "UPDATE jobs SET category_str = #{quote(label)} WHERE category = #{value}"
    end
    remove_column :jobs, :category
    rename_column :jobs, :category_str, :category
    add_index :jobs, :category
  end
end
