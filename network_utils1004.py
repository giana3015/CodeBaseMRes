import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import numpy.matlib
from matplotlib.widgets import Slider
from mpl_toolkits.mplot3d import Axes3D
from ipywidgets import interact, IntSlider, fixed

def show_bump_3D(matrix, PC_idx, timestep):
    """
    Plots the 3D bump (NetAct) at a specific timestep using a 3D surface plot.
    
    Parameters:
    - matrix: 3D array of shape (timesteps, rows, cols)
    - PC_idx: 2D array of place cell indices
    - timestep: the timestep index to visualize
    """
    Z = matrix[timestep]
    rows, cols = Z.shape
    x = np.arange(cols)
    y = np.arange(rows)
    X, Y = np.meshgrid(x, y)

    fig = plt.figure(figsize=(10, 6))
    ax = fig.add_subplot(111, projection='3d')
    surf = ax.plot_surface(X, Y, Z, cmap='YlGnBu', edgecolor='none')

    # Annotate place cell indices
    for r in range(rows):
        for c in range(cols):
            ax.text(c, r, Z[r, c] + 0.05, f"{PC_idx[r, c]}", 
                    ha='center', va='center', fontsize=7, color='black')

    ax.set_title(f'3D Bump Activation at Timestep {timestep}')
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Activation')
    plt.tight_layout()
    plt.show()

# Define the Gaussian function for firing fields
def gaussian(X, Y, cx, cy, sigma):
    """
    Computes a 2D Gaussian function centered at (cx, cy).
    """
    distance_sq = (X - cx) ** 2 + (Y - cy) ** 2
    gauss = np.exp(-distance_sq / (2 * sigma ** 2))
    return gauss / np.max(gauss)

# Function to create a 3D plot of the firing rates of cells
def create3Dplot(rows, cols, Z):
    x = np.arange(0, rows, 1)
    y = np.arange(0, cols, 1)
    X, Y = np.meshgrid(x, y)

    fig = plt.figure(figsize=(10, 6))
    ax = fig.add_subplot(111, projection='3d')
    surf = ax.plot_surface(X, Y, Z, cmap='YlGnBu', edgecolor='none')

    for r in range(Z.shape[0]):
        for c in range(Z.shape[1]):
            ax.text(c, r, Z[r, c] + 0.05, f"{r * cols + c}",
                    ha='center', va='center', fontsize=8, color='black', weight='bold')

    ax.set_title('3D Surface Plot with Place Cell Indices')
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Activation')

    plt.ion()
    plt.show()
    plt.pause(0.001)
    input("Press Enter to continue...")
    plt.close(fig)

def view_bump_with_slider_3D(results, PC_idx=None):
    """
    Interactive 3D plot slider to visualize bump movement across timesteps.
    
    Parameters:
    - results: 3D numpy array of shape (timesteps, rows, cols)
    - PC_idx: optional place cell index grid to overlay
    """
    timesteps, rows, cols = results.shape

    fig = plt.figure(figsize=(12, 7))
    ax = fig.add_subplot(111, projection='3d')
    plt.subplots_adjust(bottom=0.2)

    x = np.arange(0, rows)
    y = np.arange(0, cols)
    X, Y = np.meshgrid(x, y)

    Z = results[0]
    surf = [ax.plot_surface(X, Y, Z, cmap='YlGnBu', edgecolor='none')]

    def update_plot(t):
        ax.clear()
        Z = results[int(t)]
        surf[0] = ax.plot_surface(X, Y, Z, cmap='YlGnBu', edgecolor='none')
        ax.set_title(f'3D Bump Activity – Timestep {int(t)}')
        ax.set_xlabel('X')
        ax.set_ylabel('Y')
        ax.set_zlabel('Activation')

        # Overlay indices if provided
        if PC_idx is not None:
            for r in range(rows):
                for c in range(cols):
                    ax.text(c, r, Z[r, c] + 0.05, f"{PC_idx[r, c]}",
                            ha='center', va='center', fontsize=6, color='black')

        fig.canvas.draw_idle()

    ax_slider = plt.axes([0.2, 0.05, 0.6, 0.03])
    slider = Slider(ax_slider, 'Timestep', 0, timesteps - 1, valinit=0, valfmt='%0.0f')

    slider.on_changed(update_plot)
    plt.show()

# Function to create a 2D plot with bump peak

def create2Dplot(rows, cols, Z):
    plt.figure(figsize=(8, 6))
    plt.imshow(Z, cmap='YlGnBu', interpolation='nearest')
    plt.title('2D Firing Rate Map with Place Cell Indices')
    plt.colorbar(label='Activation')

    for r in range(rows):
        for c in range(cols):
            plt.text(c, r, f"{r * cols + c}", ha='center', va='center',
                     fontsize=8, color='black', weight='bold')

    max_idx = np.unravel_index(np.argmax(Z), Z.shape)
    plt.scatter(max_idx[1], max_idx[0], color='red', edgecolors='black',
                s=100, label='Bump Peak (Max Activity)')
    plt.legend(loc='upper right')
    plt.xlabel('X')
    plt.ylabel('Y')
    plt.tight_layout()
    plt.ion()
    plt.show()

# Function to show a 3D matrix slice
def show_slice(matrix, index):
    plt.imshow(matrix[index, :, :], cmap='YlGnBu')
    plt.colorbar()
    plt.title(f"Slice {index}")
    plt.show()

# Function to plot all sensory fields as subplots
def plot_all_sensory_fields(SensoryFiringFields, PC_idx):
    rows, cols, nSensoryCells = SensoryFiringFields.shape
    nCols = int(np.ceil(np.sqrt(nSensoryCells)))
    nRows = int(np.ceil(nSensoryCells / nCols))

    fig, axes = plt.subplots(nRows, nCols, figsize=(nCols * 2, nRows * 2))
    axes = axes.flatten()

    for i in range(nSensoryCells):
        ax = axes[i]
        im = ax.imshow(SensoryFiringFields[:, :, i], origin='upper', cmap='viridis', alpha=0.8)
        for r in range(PC_idx.shape[0]):
            for c in range(PC_idx.shape[1]):
                ax.text(c, r, f"{PC_idx[r, c]}", ha='center', va='center', color='black', fontsize=6)
        ax.set_title(f'Cell {i}', fontsize=8)
        ax.set_xticks([])
        ax.set_yticks([])

    for j in range(nSensoryCells, len(axes)):
        axes[j].axis('off')

    fig.colorbar(im, ax=axes.ravel().tolist(), shrink=0.6, label="Firing Strength")
    plt.suptitle("Sensory Firing Fields for All Sensory Cells", fontsize=14)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.show()

# Function to plot sensory input map
def plot_sensory_input_subplots(sensoryInputGrids, PC_idx, nCols=6):
    """
    Plot multiple sensory input maps as subplots across timesteps.

    Parameters:
    - sensoryInputGrids: list of tuples (sensoryInputGrid, pcRow, pcCol, timestep)
    - PC_idx: matrix of place cell indices
    - nCols: number of columns in subplot layout
    """
    nPlots = len(sensoryInputGrids)
    nRows = int(np.ceil(nPlots / nCols))

    fig, axes = plt.subplots(nRows, nCols, figsize=(20, 3 * nRows))
    axes = axes.flatten()

    for i, (grid, pcRow, pcCol, timestep) in enumerate(sensoryInputGrids):
        ax = axes[i]
        im = ax.imshow(grid, cmap='YlGnBu', interpolation='none')

        # Overlay PC indices
        for r in range(PC_idx.shape[0]):
            for c in range(PC_idx.shape[1]):
                ax.text(c, r, f"{PC_idx[r, c]}", ha='center', va='center', fontsize=6, color='black')

        # Highlight sensory input location
        ax.scatter(pcCol, pcRow, color='cyan', s=80, edgecolors='black')
        ax.set_title(f"Timestep {timestep}")
        ax.set_xticks([])
        ax.set_yticks([])

    # Hide unused axes
    for j in range(i + 1, len(axes)):
        axes[j].axis('off')

    fig.suptitle("Sensory Input Maps Across Trajectory Timesteps", fontsize=16)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.show()

# Function to plot initial activation
def plot_initial_activation(initialNetAct, PC_idx, pcRow, pcCol):
    plt.figure(figsize=(10, 6))
    plt.imshow(initialNetAct, cmap='coolwarm')
    plt.title("Initial Random Activation (NetAct)")
    plt.colorbar()

    for r in range(PC_idx.shape[0]):
        for c in range(PC_idx.shape[1]):
            plt.text(c, r, f"{PC_idx[r, c]}", ha='center', va='center',
                     fontsize=8, color='black', weight='bold')

    plt.scatter(pcCol, pcRow, color='cyan', s=100, edgecolors='black', label='Sensory Input Location')
    plt.legend()
    plt.xlabel("X")
    plt.ylabel("Y")
    plt.tight_layout()
    plt.show()

# Function to plot normalised sensory input grid
def plot_normalised_sensory_grid(sensoryInputGridNormalised):
    plt.imshow(sensoryInputGridNormalised, cmap='YlGnBu')
    plt.colorbar()
    plt.title("Normalised Sensory Input Grid")
    plt.xlabel("X")
    plt.ylabel("Y")
    plt.tight_layout()
    plt.show()

# Function to plot final activation with bump location
def plot_final_activation(NetAct):
    plt.figure(figsize=(10, 4))
    plt.imshow(NetAct, cmap='viridis')
    plt.title("Final NetAct After Recurrent Updates")
    plt.colorbar()

    final_max_idx = np.unravel_index(np.argmax(NetAct), NetAct.shape)
    flat_index = np.ravel_multi_index(final_max_idx, NetAct.shape)
    print("Final peak position (row, col):", final_max_idx)
    print("Final place cell index:", flat_index)

    plt.scatter(final_max_idx[1], final_max_idx[0], color='red', label='Final Peak')
    plt.legend()
    plt.tight_layout()
    plt.show()
def generate_evenly_spaced_centers(grid_rows, grid_cols, n_centers):
    """
    Generate approximately evenly spaced (row, col) center coordinates for a given grid.
    
    Parameters:
    - grid_rows: Number of rows in the grid
    - grid_cols: Number of columns in the grid
    - n_centers: Total number of center coordinates to generate

    Returns:
    - List of (row, col) tuples
    """
    n_rows = int(np.sqrt(n_centers))
    n_cols = int(np.ceil(n_centers / n_rows))

    row_idx = np.linspace(0, grid_rows - 1, n_rows, dtype=int)
    col_idx = np.linspace(0, grid_cols - 1, n_cols, dtype=int)

    return [(r, c) for r in row_idx for c in col_idx][:n_centers]
def generate_circular_trajectory(rows, cols, radius=4, center=None, nSteps=36, plot=True, PC_idx=None):
    """
    Generate and optionally plot a circular trajectory on a grid.

    Parameters:
    - rows, cols: dimensions of the grid
    - radius: radius of the circle
    - center: (x, y) center of the circle; if None, defaults to center of grid
    - nSteps: number of points along the circle
    - plot: if True, shows a plot of the trajectory
    - PC_idx: optional grid to overlay place cell indices

    Returns:
    - List of (row, col) trajectory positions
    """
    if center is None:
        center_x, center_y = rows // 2, cols // 2
    else:
        center_x, center_y = center

    theta = np.linspace(0, 2 * np.pi, nSteps)
    x_pos = center_x + radius * np.cos(theta)
    y_pos = center_y + radius * np.sin(theta)

    x_idx = np.clip(np.round(x_pos).astype(int), 0, rows - 1)
    y_idx = np.clip(np.round(y_pos).astype(int), 0, cols - 1)

    trajectory = list(zip(x_idx, y_idx))

    if plot:
        plt.imshow(PC_idx if PC_idx is not None else np.zeros((rows, cols)), cmap='Greys')
        plt.plot(y_idx, x_idx, marker='o', linestyle='-', color='red', label='Trajectory')
        plt.title('Circular Trajectory Over Grid')
        plt.legend()
        plt.show()

    return trajectory
def generate_edge_to_edge_trajectory(rows, cols, nSteps=20, start=(0, 0), end=None, plot=True, PC_idx=None):
    """
    Generate a trajectory from one edge of the grid to the opposite edge.

    Parameters:
    - rows, cols: dimensions of the grid
    - nSteps: number of trajectory points
    - start: starting coordinate (row, col)
    - end: ending coordinate (row, col); if None, defaults to (rows-1, cols-1)
    - plot: whether to plot the trajectory
    - PC_idx: optional grid to overlay place cell indices

    Returns:
    - List of (row, col) positions forming the trajectory
    """
    if end is None:
        end = (rows - 1, cols - 1)

    row_vals = np.linspace(start[0], end[0], nSteps).astype(int)
    col_vals = np.linspace(start[1], end[1], nSteps).astype(int)
    trajectory = list(zip(row_vals, col_vals))

    if plot:
        plt.figure(figsize=(6, 6))
        plt.imshow(PC_idx if PC_idx is not None else np.zeros((rows, cols)), cmap='Greys')
        plt.plot(col_vals, row_vals, color='red', marker='o', label='Trajectory')
        plt.title('Edge-to-Edge Trajectory Over Grid')
        plt.legend()
        plt.grid(False)
        plt.show()

    return trajectory
def initialize_weights(rows, cols, PC_idx):
    """
    Initialize a 3D weights matrix for a 2D place cell grid.

    Each cell has a self-connection weight of 1 and weights of 0.5 
    to its immediate neighbors (up, down, left, right).

    Parameters:
    - rows, cols: dimensions of the place cell grid
    - PC_idx: 2D array of place cell indices

    Returns:
    - weightsMat: 3D array of shape (rows, cols, nCells)
    """
    nCells = rows * cols
    weightsMat = np.zeros((rows, cols, nCells))

    for k in range(nCells):
        r, c = np.where(PC_idx == k)
        r, c = r[0], c[0]

        weightsMat[r, c, k] = 1.0  # Self-connection

        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols:
                weightsMat[nr, nc, k] = 0.5

    return weightsMat

def plot_trajectory_over_PC_idx(trajectory_positions, PC_idx):
    plt.imshow(PC_idx, cmap='Greys')
    traj = np.array(trajectory_positions)
    plt.plot(traj[:, 1], traj[:, 0], color='red', marker='o', linewidth=1, markersize=2)
    plt.title("Trajectory Over Place Cell Grid")
    plt.xlabel("X")
    plt.ylabel("Y")
    plt.gca().invert_yaxis()
    plt.show()

def plot_trajectory_over_PC_idx(trajectory_positions, PC_idx):
    """
    Plot a trajectory over the place cell index grid.

    Parameters:
    - trajectory_positions: list of (row, col) positions representing the trajectory
    - PC_idx: 2D array of place cell indices
    """
    rows, cols = PC_idx.shape

    plt.figure(figsize=(8, 6))
    plt.imshow(PC_idx, cmap='Greys', interpolation='none')
    plt.title('Agent Trajectory Over Place Cell Grid')

    # Unpack the trajectory coordinates
    ys, xs = zip(*trajectory_positions)
    plt.plot(xs, ys, marker='o', linestyle='-', color='red', label='Trajectory')

    # Optionally overlay the PC indices
    for r in range(rows):
        for c in range(cols):
            plt.text(c, r, f"{PC_idx[r, c]}", ha='center', va='center',
                     fontsize=8, color='black', weight='bold')

    plt.legend()
    plt.xlabel('X (columns)')
    plt.ylabel('Y (rows)')
    plt.tight_layout()
    plt.show()
def plot_maze_over_PC_idx(env, PC_idx, trajectory=None, show_indices=False,
                          maze_color='blue', traj_color='red', lw=2):
    """
    Overlays a RatInABox maze (walls) and optional trajectory on a place cell index grid.

    Parameters:
        env (ratinabox.Environment): Environment object containing wall definitions.
        PC_idx (np.ndarray): 2D array of place cell indices.
        trajectory (list of (row, col)): Optional list of trajectory positions in grid space.
        show_indices (bool): Whether to show numeric place cell indices on the grid.
        maze_color (str): Color of the maze walls.
        traj_color (str): Color of the trajectory line.
        lw (float): Line width for maze wall plotting.
    """
    rows, cols = PC_idx.shape
    plt.figure(figsize=(8, 6))
    plt.imshow(PC_idx, cmap='Greys', interpolation='none', origin='upper')
    plt.title('Maze with Trajectory Over Place Cell Grid')

    if show_indices:
        for r in range(rows):
            for c in range(cols):
                plt.text(c, r, f"{PC_idx[r, c]}", ha='center', va='center',
                         fontsize=6, color='black')

    # Plot walls
    for wall in env.walls:
        (x0, y0), (x1, y1) = wall
        x0_scaled, x1_scaled = x0 * (cols - 1), x1 * (cols - 1)
        y0_scaled, y1_scaled = y0 * (rows - 1), y1 * (rows - 1)
        plt.plot([x0_scaled, x1_scaled], [y0_scaled, y1_scaled],
                 color=maze_color, linewidth=lw)

    # Plot trajectory if provided
    if trajectory:
        ys, xs = zip(*trajectory)
        plt.plot(xs, ys, marker='o', linestyle='-', color=traj_color,
                 label='Trajectory', markersize=3)
        plt.legend()

    plt.xlabel("X (columns)")
    plt.ylabel("Y (rows)")
    plt.gca().invert_yaxis()
    plt.tight_layout()
    plt.show()