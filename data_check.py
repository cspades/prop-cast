import numpy as np
import os

flag = 0
count = 0

for file in os.listdir(os.getcwd()):
    print(file)
    if file.endswith(".npy"):
        print(np.load(file).shape)
        x = np.load(file)
        # Check for files that don't have enough time slices.
        if file.endswith("_input.npy") and x.shape[0] != 15:
            flag = 1
            print("\t CORRUPT FILE =", file)
        # Check for files that don't have enough data.
        if np.sum(x) == 0:
            flag = 1
            print("\t CORRUPT FILE =", file)
        # Count files.
        count += 1

print("Count =", count)
print("Corrupt? =", bool(flag))

