class AddStartedAtToExtfaceJob < ActiveRecord::Migration
  def change
    add_column :extface_jobs, :started_at, :timestamp
  end
end
