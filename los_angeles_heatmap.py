# --------------------------------------------------------------------------- #
# Heatmap imaging from raw matrix data
# Author: Dimitri Zafirov
# Purpose: ECE C247 project code to prepare data for ML.
# Permissions: Shared with Core Ye and ECE C247.
# --------------------------------------------------------------------------- #


import os
import pickle
import requests
from collections import namedtuple, defaultdict

import folium
import xmltodict
import numpy as np
from folium.plugins import HeatMap

import warnings



import pandas as pd, numpy as np
from numpy import genfromtxt
dir = "C:/Users/canth/Dropbox/UCLA/A2 Neural Networks/project/pred_results/pred_heatmap_LA"




for k in range(18,19):
    print(str(k))
    file = 'la_heatmap_ts_'+str(k)

    if k == 16: file = "pred_heatmap_opt_LA"
    if k==17: file = "pred_heatmap_opt_alt_LA"
    if k==18: file = "test_heatmap_opt_LA"

    ############################################################
    # Preparing data for heatmap, going from matrix to array
    # with (lat, lon, avg price) observations for each cell
    ############################################################

    raw_data = genfromtxt(dir+'/'+file+'.csv', delimiter=',')
    raw_data.shape
    lat_coordinates = np.zeros(raw_data.shape[0])
    lon_coordinates = np.zeros(raw_data.shape[1])

    location=[34.196398, -118.261862]

    gran = 15 # must be identical to the one used in read_convert_data.py to generate the maps

    top_left_coord = [location[0]+60*gran/3600, location[1]-60*gran/3600]

    for i in range(0,121):
        lat_coordinates[i] = top_left_coord[0] - i*gran/3600
        lon_coordinates[i] = top_left_coord[1] + i*gran/3600

    # To initialize the array,  will be dropped after the loop
    data = np.array([lat_coordinates[0], lon_coordinates[0], raw_data[0,0]])
    data = np.append([data],[np.array([lat_coordinates[1], lon_coordinates[0], raw_data[0,1]])], axis=0)

    for i in range(0,121):
        for j in range(0, 121):
            data = np.append(data, [np.array([lat_coordinates[i], lon_coordinates[j], raw_data[i, j]])], axis=0)

    data = np.delete(data, (0), axis=0)
    data = np.delete(data, (0), axis=0)

    np.savetxt(dir+'\LA_data.txt', data, delimiter=',')

    ############################################################
    # data ready, now inserting into mapping process with image output
    ############################################################
    out_fn = 'LA_heatmap.html'
    generate_new = False

    m = folium.Map(
        location=location,
        control_scale=True,
        tiles='Mapbox Bright',
        zoom_start=11
    )

    radius = 10
    hm = HeatMap(
        data,
        radius=radius,
        blur=int(2 * radius)
    )
    hm.add_to(m)

    m.save(out_fn)
    print('View the map with a browser by opening {}.'.format(out_fn))

    ############################################################
    # map image output
    ############################################################

    from selenium import webdriver
    driver = webdriver.Chrome(executable_path = 'C:/Users/canth/Dropbox/UCLA/A2 Neural Networks/project/chromedriver.exe')

    driver.set_window_size(1600, 1200)  # choose a resolution
    driver.get('C:/Users/canth/Dropbox/UCLA/A2 Neural Networks/project/' + out_fn)
    # You may need to add time.sleep(seconds) here
    driver.save_screenshot(dir+'/'+file+'.png')
    driver.close()