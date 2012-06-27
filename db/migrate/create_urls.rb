Sequel.migration do
  up do
    create_table(:urls) do
      String :url, :null=>false
      String :code, :null=>false
      index :code, :unique=>true
      index :url, :unique=>true
    end
  end
  down do
    drop_table(:urls)
  end
end