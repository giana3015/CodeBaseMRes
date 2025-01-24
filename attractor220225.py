import numpy as np
import matplotlib.pyplot as plt

# STEP 1: Define grid and weight matrix sizes
grid_size = 20  # Size of the place cell grid (20x20)
weight_matrix_elements = 400  # Each weight matrix is 20x20 (flattened to 400)

# STEP 2: Create a 3D array to store weight matrices
# The array has dimensions (20x20 grid) x (400 weights per place cell)
weight_matrices = np.zeros((grid_size, grid_size, weight_matrix_elements))

# Function to compute Gaussian weights
def gaussian_weight(distance, sigma=1.0):
    return np.exp(-0.5 * (distance / sigma) ** 2)

# STEP 3: Update transient movement weights for each place cell
for row_index in range(grid_size):
    for col_index in range(grid_size):
        # Create an empty 20x20 weight matrix for the current place cell
        current_weight_matrix = np.zeros((grid_size, grid_size))
        
        # Update the weights for the current place cell and its neighbors
        current_weight_matrix[row_index, col_index] = gaussian_weight(0)  # Center cell
        if row_index > 0:
            current_weight_matrix[row_index - 1, col_index] = gaussian_weight(1)  # Above
        if row_index < grid_size - 1:
            current_weight_matrix[row_index + 1, col_index] = gaussian_weight(1)  # Below
        if col_index > 0:
            current_weight_matrix[row_index, col_index - 1] = gaussian_weight(1)  # Left
        if col_index < grid_size - 1:
            current_weight_matrix[row_index, col_index + 1] = gaussian_weight(1)  # Right
        
        # Flatten the 20x20 weight matrix (400 elements) and store it in the 3D array
        weight_matrices[row_index, col_index, :] = current_weight_matrix.flatten()

"""
#  Add noise to a single randomly selected weight matrix to stimulate Alzheimer's
random_row = np.random.randint(0, grid_size)  # Randomly select a row index for the weight matrix
random_col = np.random.randint(0, grid_size)  # Randomly select a column index for the weight matrix

# Retrieve the randomly selected weight matrix and reshape it to 20x20
random_weight_matrix = weight_matrices[random_row, random_col, :].reshape(grid_size, grid_size)

# Generate a random noise array (20x20)
noise = np.random.rand(grid_size, grid_size)

# Scale the noise to control its intensity
noise_intensity = 0.2  # Adjust this value as needed (e.g., 0.1 for subtle noise, 1.0 for strong noise)
scaled_noise = 1 + (noise - 0.5) * noise_intensity

# Apply noise to the randomly selected weight matrix
noisy_weight_matrix = scaled_noise * random_weight_matrix

# Update the selected weight matrix in the 3D array with the noisy version
weight_matrices[random_row, random_col, :] = noisy_weight_matrix.flatten()

"""

# STEP 4: Generate random sensory input
# Create a random 20x20 sensory input matrix
sensory_input = np.random.rand(grid_size, grid_size)

# STEP 5: Initialize an empty output array to store results
output = np.zeros((grid_size, grid_size))

# STEP 6: For each place cell, update based on sensory input and weight matrix
for row_index in range(grid_size):
    for col_index in range(grid_size):
        # Retrieve and reshape the weight matrix for the current place cell (from 1D to 20x20)
        current_weight_matrix = weight_matrices[row_index, col_index, :].reshape(grid_size, grid_size)
        
        # Compute the weighted sum by applying the weight matrix to the sensory input
        weighted_sum = np.sum(sensory_input * current_weight_matrix)
        
        # Store the computed weighted sum in the corresponding output cell
        output[row_index, col_index] = weighted_sum

# Visualize the output matrix
plt.figure(figsize=(6, 6)) #plot it as a 6x6 inches graph
plt.imshow(output, cmap='hot') #display 2D output array as image and each element as a pixel, with a hot colour map
plt.colorbar()
plt.title("place cell activity")
plt.show()