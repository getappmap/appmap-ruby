Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      text :login, null: false, unique: true
      column :password_digest, :bytea
    end
  end
end
