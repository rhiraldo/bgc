import matplotlib.pyplot as plt
import requests
import os

# Define the API endpoint
api_url = "http://mysite.com/api/data"

# Function to retrieve data for a person from the API
def get_data_for_person(person):
    params = {"person": person}
    response = requests.get(api_url, params=params)
    if response.status_code == 200:
        data = response.json()
        return data
    else:
        print(f"Failed to retrieve data for {person}.")
        return []

# Get a list of people from environment variables
people_env_var = os.environ.get("PEOPLE", "").split(",")
people = [person.strip() for person in people_env_var]

# Create the plot
plt.figure(figsize=(12, 6))  # Adjust the figure size if needed

for person in people:
    data = get_data_for_person(person)
    if data:
        x_values = [item["month"] for item in data]
        y_values = [float(item["value"]) for item in data]
        plt.plot(x_values, y_values, marker='o', label=person)

plt.xlabel('Month')
plt.ylabel('Value')
plt.title('Performance Comparison')
plt.grid(True)
plt.xticks(rotation=45)
plt.legend()
plt.tight_layout()

# Show the plot
plt.show()
