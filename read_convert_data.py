# --------------------------------------------------------------------------- #
# Data Processing Tools for AttomData Housing Index Database
# Author: Cory Ye
# Purpose: ECE C247 project code to prepare data for ML.
# Permissions: Shared with Dimitri Zafirov (source of data) and ECE C247.
# --------------------------------------------------------------------------- #

import json
import os
import numpy as np
import pandas as pd
import time

# Recursive Method to Parse Architecture of Nested Dictionary Data for Database Analysis
# def recursive_items(dictionary, lvl):
#     for key, value in dictionary.items():
#         # Append key, dictionary, nesting level,
#         # and if the data is a leaf/dead-end, then print data!
#         if type(value) is dict:
#             yield (key, value, lvl, False)
#             yield from recursive_items(value, lvl+1)
#         else:
#             yield (key, value, lvl, True)

def convert_time(t, date=True):
    """
    Convert YYYY-MM-DD string to integer time step if date is True.
    Otherwise, convert integer time step to YYYY-MM-DD string.
    """
    if date:
        t_split = t.split('-')
        y = int(t_split[0])
        m = int(t_split[1])
        d = int(t_split[2])
        return y * 365 + m * 31 + d
    else:
        y = t // 365
        m = (t % 365) // 31
        d = (t % 365) % 31
        return str(y)+'-'+str(m)+'-'+str(d)

def convert_loc(px, py, gran=15, map=True):
    """
    Convert (px=longitude, py=latitude) to integer coordinates for spatial analysis and convolution on a 2-D grid.
    gran: Second-level granularity of the mapping. 1 second (or 1/3600 degrees of) longitude/latitude is about 30 meters.
    If map=False, then retrieve an approximate longitude and latitude from the integer coordinate on the 2-D grid.
    """
    if map:
        return round(float(px) * 3600 / gran), round(float(py) * 3600 / gran)
    else:
        return px * gran / 3600, py * gran / 3600

def spacetime_integrate(data, time_frame, space_frame, center, complete=True):
    """
    Integrate a sufficient amount of data over a fixed period of time.
    :param data: NumPy array with processed property transaction data. Sorted in time and space in order (t,x,y).
    :param time_frame: Time interval (in day-length time steps) of integration.
    :param space_frame: Dimension (in spatial units) of the (square-cropped) spatial map.
    Sets the gran-resolution spatial dimension of the 2-D feature matrix to an odd integer S.
    :param center: Center (longitude, latitude) coordinates in spatial units of a region, i.e. city.
    :return: (T, S, S, K) time-series data tensor that represents the 2-D heatmap of property transactions with
    T time-steps of time_frame intervals and K property characteristics (i.e. price, proptype, etc.).
    """
    # Initialize list of time-slice heat-maps. Concatenate elements to construct a time-series of heat-maps.
    map_cache = []

    # Normalize the spatial coordinates of the data to center.
    data[:, 1] -= center[0]
    data[:, 2] -= center[1]

    # Loop over intervals of time.
    t = data[0, 0]      # Initial time of data subset.
    k = 0               # Time interval multiplier.
    while True:
        # Compute index mask of data within the time interval
        # t + [k*time_frame, (k+1)*time_frame).
        time_index = np.logical_and(data[:, 0] >= t + k*time_frame,
                                    data[:, 0] < t + (k+1)*time_frame)
        if not np.any(time_index):
            # All data integrated, assuming that there are no temporal
            # discontinuities in the data with length greater than time_frame.
            break
        # Filter out the data in time interval/slice k.
        data_tsf = data[time_index, :]

        # Intialize time-slice spatial matrix with features, i.e. excepting time and space.
        dim = int(np.floor(space_frame/2) + np.ceil(space_frame/2) + 1)
        if complete:
            spat_map = np.zeros((dim, dim, data.shape[1] - 3))
        else:
            spat_map = np.zeros((dim, dim))

        # Extract and crop the spatial coordinates to dimension space_frame.
        for x in range(-int(np.floor(space_frame/2)), int(np.ceil(space_frame/2) + 1)):
            for y in range(-int(np.floor(space_frame/2)), int(np.ceil(space_frame/2) + 1)):
                # Compute index mask of data for the fixed spatial coordinates (x,y).
                space_index = np.logical_and(data_tsf[:, 1] == x, data_tsf[:, 2] == y)
                if not np.any(space_index):
                    # No transaction at coordinate (x,y). Continue extraction.
                    continue

                # Extract and interpolate the non-spatial data in the time interval.
                data_avg = np.mean(data_tsf[space_index, :], axis=0)

                # Insert the averaged data in the time-slice matrix at (x,y).
                if complete:
                    spat_map[x, y, :] = data_avg[3:]
                else:
                    spat_map[x, y] = data_avg[3:]

        # Cache the time-slice spatial feature matrix in chronological order.
        map_cache.append(spat_map)

        # Increment time interval.
        k += 1

    # Concatenate all elements in the cache of spatial feature matrix to a time-series of heat-maps.
    time_map = np.array(map_cache, dtype=np.single)

    # Return the heat-map time series with dimension (T,S,S,K).
    return time_map


# ------------------------------------------------- #
# Data Processing Method for AttomData Database
# ------------------------------------------------- #

def data_process(tf, sf, spat_res, center, dir, region, exog_features, complete=True):

    # data_cache is a list of tuples containing housing transaction data.
    # data_cache = [ ..., (saleTransDate, longitude, latitude, saleamt, proptype, yearbuilt, elevation,
    #                      lotSize1, universalsize, beds, bathstotal, priceperbed, pricepersizeunit, ...), ... ]
    data_cache = []


    # Search CWD for all JSON data in format .txt.
    for filename in os.listdir(dir):
        # Analyze data files, specify county .
        if filename.endswith(".txt") and filename.find(region) > -1:
            # Read file to list of dictionaries.
            f = open(dir + "/" + filename, 'r')
            data = json.loads('[' + f.read() + ']')
            print(filename)

            # Extract and process the data.
            for d in data:
                if (d.__len__() > 1): # there's transaction data in that file
                    for p in d['property']:

                        # # Map out architecture of source data.
                        # for key, value, lvl, leaf in recursive_items(p, 0):
                        #     print(lvl*'\t'+str(key))
                        #     if leaf == True:
                        #         print(lvl*'\t'+str(value))

                        # Get exogenous variables for the year of the observation.
                        t = p['sale']['salesearchdate']

                        # Extract and process training and description data for ML.
                        time = convert_time(t)
                        x, y = convert_loc(p['location']['longitude'], p['location']['latitude'], gran=spat_res)
                        price = p['sale']['amount']['saleamt']
                        prop = float(p['summary']['propIndicator'])
                        origin = p['summary']['yearbuilt']
                        elev = p['location']['elevation']
                        p_size = p['lot']['lotSize1']
                        b_size = p['building']['size']['universalsize']
                        beds = p['building']['rooms']['beds']
                        baths = p['building']['rooms']['bathstotal']
                        ppb = p['sale']['calculation']['priceperbed']
                        ppu = p['sale']['calculation']['pricepersizeunit']

                        # Append data as tuple to data cache.
                        year = int(t.split('-')[0])
                        if complete: # Input data. Exogenous features also appended here.
                            if year <= 2018: # Exogenous features only exist until 2018.
                                exogs = exog_features.loc[exogenous_features['date'] == year]
                                data_cache.append([time, x, y, price, prop, origin, elev, p_size, b_size, beds, baths, ppb, ppu] + exogs.drop(columns='date').values.tolist()[0])
                        else: # Output data.
                            if year > 2018:
                                data_cache.append((time, x, y, price))

            # Close file.
            f.close()
            continue
        else:
            continue

    # Sort all data with respect to time and space.
    data_array = np.array(sorted(data_cache, key=lambda z: (z[0], z[1], z[2])), dtype=np.single)
    print(data_array.shape)

    # Convert longitudinal/latitudinal degrees to res-granularity spatial units for space_frame.
    s, _ = convert_loc(sf, 0, gran=spat_res)
    cx, cy = convert_loc(center[0], center[1], gran=spat_res)

    # Compress the data through spatio-temporal interpolation.
    out = spacetime_integrate(data_array, tf, s, (cx, cy), complete=complete)
    print(out.shape)
    # Convert array to .npy file with np.save(). Extract compressed file with np.load().
    # Change the file name as necessary to organize the processed data!
    if complete:
        np.save(region + "_heatmap_time_data_input", out)
    else:
        np.save(region + "_heatmap_time_data_output", out)





# -------------------------------------------------------------------------------------------------------------- #

# Timer
# start = time.time()

# Execute data processing method on data in CWD.
"""
tf is the time frame of interpolation in days.
sf is the space frame in degrees longitude/latitude.
spat_res is the resolution of the spatial unit in conversion to heatmap.
center is the center coordinate of the data in degrees longitude/latitude.
region is the county being processed
exog_features is the exogenous features being added to that county every year
complete is the flag for whether to include the other features in the data.
"""

dir = "C:/Users/cory0/Downloads/C247 Project Cache/"
counties = pd.read_csv(dir+'cities_by_major_county_with_centers.csv') # source of lat/lon county centroids: https://en.wikipedia.org/wiki/User:Michael_J/County_table
exogenous_features = pd.read_csv(dir+'county macro data/selected_data.csv')
exogenous_features = exogenous_features.drop(exogenous_features.columns[0], axis=1)

for i in range(1, len(counties)):
    print(counties.iloc[i]['countystate'])
    print(counties.iloc[i]['countynum'])

    df = exogenous_features.loc[exogenous_features['countynum'] == counties.iloc[i]['countynum']]
    df = df.drop(columns='countynum')

    data_process(tf=365, sf=0.5, spat_res=15, center=(counties.iloc[i]['longitude'], counties.iloc[i]['latitude']),
                 dir=dir+"countydata", region=counties.iloc[i]['file'], exog_features=df, complete=True)

# end = time.time()
# print("Time Elapsed: ", end - start)
