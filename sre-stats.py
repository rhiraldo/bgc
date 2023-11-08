import matplotlib.pyplot as plt

# Sample data from your API response
data = [
    {"month": "Aug-15-2023", "value": "80.74", "keyVal": "null"},
    {"month": "Sep-01-2023", "value": "81.25", "keyVal": "null"},
    {"month": "Sep-15-2023", "value": "78.41", "keyVal": "null"}
]

# Extract the x and y values from the data
x_values = [item["month"] for item in data]
y_values = [float(item["value"]) for item in data]

# Create the plot
plt.figure(figsize=(10, 6))  # Adjust the figure size if needed
plt.plot(x_values, y_values, marker='o', linestyle='-', color='b', label='Data')
plt.xlabel('Month')
plt.ylabel('Value')
plt.title('API Data Plot')
plt.grid(True)

# Rotate x-axis labels for better readability (optional)
plt.xticks(rotation=45)

# Show a legend
plt.legend()

# Show the plot
plt.tight_layout()
plt.show()