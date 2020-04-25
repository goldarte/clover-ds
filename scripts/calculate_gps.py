import os
import math
from geographiclib.geodesic import Geodesic

Earth = Geodesic.WGS84

default_lat = 55.703712
default_lon = 37.724518

lat = float(os.environ.get('LAT', default_lat))
lon = float(os.environ.get('LON', default_lon))
dx = float(os.environ.get('DX', 0))
dy = float(os.environ.get('DY', 0))

def dist(x, y):
    return math.sqrt(x**2+y**2)

def azi(x, y):
    return 90 - math.atan2(dy,dx)*180/math.pi

new = Earth.Direct(lat, lon, azi(dx,dy), dist(dx,dy))

print('export PX4_HOME_LAT={} PX4_HOME_LON={}'.format(new['lat2'], new['lon2']))