#! /bin/sh

# Pick a region
reg_name=SA_3

# Restrict analyses to just this region
g.region -p rast=$reg_name

# Extract stream network
# 30-meter DEMs, so threshold=1000 means that the threshold drainage area
# to define a channel is 1000 * (0.03 km)^2 = 0.9 km^2
r.stream.extract elev=$reg_name stream_vector=streams_$reg_name stream_raster=streams_$reg_name d8cut=0 memory=4000 direction=flowdir_$reg_name threshold=1000

# Snap the measurement locations to the closest stream line
# First, install the extension
g.extension r.stream.snap
# Search radius is in cells, so * 30 m -- pick a distance at which you still 
# feel confident that the data point IS really associated wtih the given river
r.stream.snap in=REE_data_points out=REE_data_points_SnappedToChannels_$reg_name stream_rast=streams_$reg_name radius=10 memory=1500 --o
# Rebuild the table
v.db.addtable map=REE_data_points_SnappedToChannels_$reg_name
# Bring database table information back from full REE data set
# TO DO: join by category, ... ??? ###########################################!!
# And give the locations in the map
v.to.db map=REE_data_points_SnappedToChannels_$reg_name option=coor columns=lon,lat units=degrees

# Build drainage basins for every point
# Using categories right now, but in future, let's use some other set of
# identifiers (since GRASS just creates categories arbitrarily / in order)
for _cat in `v.db.select map=REE_data_points_SnappedToChannels_$reg_name col=cat -c`
do
    echo $_cat
    _lon=`v.db.select map=REE_data_points_SnappedToChannels_$reg_name col=lon where="cat=$_cat" -c`
    _lat=`v.db.select map=REE_data_points_SnappedToChannels_$reg_name col=lat where="cat=$_cat" -c`
    r.water.outlet input=flowdir_$reg_name output=watershed_$_cat coordinates=$_lon,$_lat --o
done


