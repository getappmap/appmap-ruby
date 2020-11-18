Sequel.migration do
  change do
    create_table(:schema_migrations) do
      column :filename, "text", :null=>false
      
      primary_key [:filename]
    end
    
    create_table(:users) do
      primary_key :id
      column :login, "text", :null=>false
      column :password_digest, "bytea"
      
      index [:login], :name=>:users_login_key, :unique=>true
    end
  end
end
Sequel.migration do
  change do
    self << "SET search_path TO \"$user\", public"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20190728211408_create_users.rb')"
  end
end
