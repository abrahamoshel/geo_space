class CreateLandUnits < ActiveRecord::Migration
  def change
    create_table :land_units do |t|
      t.string :name
      t.geometry :location, srid: 3785
      t.geometry :movement, srid: 3785
      t.decimal :yield_vol, precision: 15, scale: 10

      t.timestamps
    end
  end
end
