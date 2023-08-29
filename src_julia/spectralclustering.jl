using LinearAlgebra
using Statistics
using Clustering

# number of clusters
no_cluster = 2

# Compute the Laplacian by defining the Diagonal and the adjacency matrix
D = Diagonal([4, 1, 1, 1, 5, 1, 1, 1, 1])
W = [0 1 1 1 1 0 0 0 0;
     1 0 0 0 0 0 0 0 0;
     1 0 0 0 0 0 0 0 0;
     1 0 0 0 0 0 0 0 0;
     1 0 0 0 0 1 1 1 1;
     0 0 0 0 1 0 0 0 0;
     0 0 0 0 1 0 0 0 0;
     0 0 0 0 1 0 0 0 0;
     0 0 0 0 1 0 0 0 0]

L = D - W

# Print the Laplacian Matrix
println("Laplacian Matrix of this graph:")
for i in 1:size(L, 1)
     println(L[i, :])
end

# compute the eigenvalues and eigenvectors
res_eigen = eigen(L)
eigen_vectors = res_eigen.vectors[:, end-(no_cluster - 1):end]

# Print the eigenvalues and eigenvectors
println("Eigenvalues")
println(res_eigen.values)
println("Eigenvectors:")
for i in 1:size(eigen_vectors, 1)
     println(eigen_vectors[i, :])
end

# cluster with k-means algorithm
eigen_vectors = transpose(eigen_vectors)
res_kmeans = kmeans(eigen_vectors, no_cluster)

# Print the Assignments. The n-th entry corresponds to the n-th node in the Graph
println("Assignments:")
print(assignments(res_kmeans))


