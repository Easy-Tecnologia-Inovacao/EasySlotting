class SyncUidWithEmailOnUsers < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL.squish
      UPDATE users SET uid = email WHERE uid IS NULL OR uid = '' OR uid != email
    SQL
  end

  def down
  end
end
