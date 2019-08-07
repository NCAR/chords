class ChangeLatLonFieldToDecimal < ActiveRecord::Migration

  def change
    change_column :sites, :lat, :decimal, :precision => 12, :scale => 9
    change_column :sites, :lon, :decimal, :precision => 12, :scale => 9
    change_column :sites, :elevation, :decimal, :precision =>12, :scale => 6
  end
end
