from sklearn.cluster import SpectralClustering
import numpy as np
L = np.array([[4, -1, -1, -1, -1, 0, 0, 0, 0],
     [-1, 1, 0, 0, 0, 0, 0, 0, 0],
     [-1, 0, 1, 0, 0, 0, 0, 0, 0],
     [-1, 0, 0, 1, 0, 0, 0, 0, 0],
     [-1, 0, 0, 0, 5, -1, -1, -1, -1,],
     [0, 0, 0, 0, -1, 1, 0, 0, 0],
     [0, 0, 0, 0, -1, 0, 1, 0, 0],
     [0, 0, 0, 0, -1, 0, 0, 1, 0],
     [0, 0, 0, 0, -1, 0, 0, 0, 1]])

print(L)
clustering = SpectralClustering(n_clusters=2, random_state=0).fit(L)
print(clustering.labels_)
