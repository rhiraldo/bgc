import matplotlib.pyplot as plt
import requests
import os

# Define the API endpoint for leaderboard and trends
leaderboard_url = "http://mysite.com/api/leaderboard"
trends_url = "http://mysite.com/api/trends/{}"

# Function to retrieve the list of top N people from the leaderboard API
def get_top_people_list(api_url, top_n=3):
    response = requests.get(api_url)
    if response.status_code == 200:
        data = response.json()
        leaderboard = data.get("leaderBoard", [])
        top_people = leaderboard[:top_n]
        return [{"name": person["name"], "id": person["id"], "appIds": person.get("appIds", [])} for person in top_people]
    else:
        print("Failed to retrieve the leaderboard.")
        return []

# Function to retrieve trend data for an API and aggregate scores
def get_aggregated_trend_data(api_url, api_name, app_ids):
    aggregated_data = {"month": [], "score": []}

    for app_id in app_ids:
        trend_url = api_url.format(api_name)
        params = {"appId": app_id}
        response = requests.get(trend_url, params=params)
        if response.status_code == 200:
            trend_data = response.json()
            for entry in trend_data:
                month = entry.get("month")
                score = float(entry.get("score", 0))
                if month and score:
                    if month not in aggregated_data["month"]:
                        aggregated_data["month"].append(month)
                        aggregated_data["score"].append(score)
                    else:
                        index = aggregated_data["month"].index(month)
                        aggregated_data["score"][index] += score

    return aggregated_data

# Get the list of top 3 people with name, ID, and appIds
top_people_list = get_top_people_list(leaderboard_url, top_n=3)

# Create the plot
plt.figure(figsize=(12, 6))  # Adjust the figure size if needed

for person in top_people_list:
    for api_name in ["SLO", "AUTOMATION_TOIL_REDUCTION", "STABILITY_RELIABILITY_RESILIENCE", "MONITORING_OBSERVABILITY"]:
        trend_data = get_aggregated_trend_data(trends_url, api_name, person["appIds"])
        plt.plot(trend_data["month"], trend_data["score"], marker='o', label=f"{person['name']} - {api_name}")

plt.xlabel('Month')
plt.ylabel('Aggregated Score')
plt.title('API Trends Comparison')
plt.grid(True)
plt.xticks(rotation=45)
plt.legend()
plt.tight_layout()

# Show the plot
plt.show()
