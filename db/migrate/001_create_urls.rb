Sequel.migration do
  up do
    create_table :urls do
      String :code, :unique => true, :null => false
      String :url, :unique => true, :null => false
    end
  end
  down do
    drop_table(:urls)
  end
end