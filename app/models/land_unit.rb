class LandUnit < ActiveRecord::Base
  module Factories
    GEO = RGeo::Geographic.simple_mercator_factory
    PROJECTED = GEO.projection_factory
  end

  set_rgeo_factory_for_column(:location, Factories::PROJECTED)
  set_rgeo_factory_for_column(:movement, Factories::PROJECTED)

  def self.read_shapefile(shapefile_path)
    srs_database = RGeo::CoordSys::SRSDatabase::ActiveRecordTable.new

    factory = RGeo::Geos.factory(:srs_database => srs_database, :srid => 96805)
    cartesian_preferred_factory = LandUnit.rgeo_factory_for_column(:location)
    cartesian_factory = LandUnit.rgeo_factory_for_column(:movement)

    RGeo::Shapefile::Reader.open(shapefile_path, factory: factory) do |file|
        # lu = LandUnit.find_or_create_by(name: )
      file.each do |record|
        casting = RGeo::Feature.cast(Factories::GEO.point(
          record.attributes["LONGITUDE"],
          record.attributes["LATITUDE"]),
          cartesian_preferred_factory,
          :project)

        cartesian_cast = RGeo::Feature.cast(record.geometry,
          cartesian_factory,
          :project)

        if cartesian_cast
          lu = LandUnit.new(
            name: "#{record.attributes['CLIENT_NAM']} \
            #{record.attributes['CLIENT_NAM']} \
            #{record.attributes['FIELD_NAME']}",
            yield_vol: record.attributes["VRYIELDVOL"]
          )
          lu.location = casting
          lu.movement = cartesian_cast[0]
          lu.save
        end
      end
    end
  end


  # Project a latitude, longitude point to X,Y coordinates in our projection
  def self.projected_point(coordinate)
    geo_point = Factories::GEO.point(coordinate[:longitude], coordinate[:latitude])
    Factories::GEO.project(geo_point)
  end

  # Project an array of latitude, longitude points representing a polygon to X,Y coordinates
  def self.projected_polygon(geo_coordinates)
    points = geo_coordinates.map{|c| Factories::GEO.point(c[:longitude], c[:latitude]) }
    line_string = Factories::GEO.line_string(points)
    polygon = Factories::GEO.polygon(line_string)

    Factories::GEO.project(polygon)
  end

  def coordinate
    @coordinate ||= begin
      {longitude: location.x, latitude: location.y}
    end
  end
  # Returns array of latitude-longitude hashes
  # Ex: [{latitude: 1, longitude: 2}, {latitude: 3, longitude: 4}]
  def coordinates
    @coordinates ||= begin
      geo_points = LandUnit::Factories::GEO.unproject(movement).exterior_ring.points
      coordinates = geo_points.inject(Set.new) do |set, point|
        set.add({longitude: point.longitude, latitude: point.latitude})
      end
      coordinates.to_a
    end
  end

  # Update the polygon stored in the database by sending in array of latitude, longitude points
  # Ex: [{latitude: 1, longitude: 2}, {latitude: 3, longitude: 4}]
  def coordinates=(coordinates)
    self.location = LandUnit.projected_polygon(coordinates).as_text
  end
end
