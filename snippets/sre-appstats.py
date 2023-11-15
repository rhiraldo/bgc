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
        return top_people
    else:
        print("Failed to retrieve the leaderboard.")
        return []

# Function to retrieve trend data for an API and aggregate scores
def get_aggregated_trend_data(api_url, api_name, app_id):
    trend_url = api_url.format(api_name)
    params = {"appId": app_id}
    response = requests.get(trend_url, params=params)
    if response.status_code == 200:
        trend_data = response.json()
        aggregated_data = {"month": [], "score": []}
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
    else:
        print(f"Failed to retrieve trend data for appId {app_id} and API {api_name}.")
        return {"month": [], "score": []}

# Get the list of top N people with detailed leaderboard data
top_people_list = get_top_people_list(leaderboard_url, top_n=3)

# Create a dictionary to store aggregated scores for each person, category, and month
aggregated_scores = {}

for person in top_people_list:
    person_name = person.get("name")
    app_leaderboards = person.get("ctoLeaderBoards", [])

    for app_leaderboard in app_leaderboards:
        app_leaderboard_name = app_leaderboard.get("appName")
        app_leaderboard_id = app_leaderboard.get("appId")

        for api_name in ["SLO", "AUTOMATION_TOIL_REDUCTION", "STABILITY_RELIABILITY_RESILIENCE", "MONITORING_OBSERVABILITY"]:
            trend_data = get_aggregated_trend_data(trends_url, api_name, app_leaderboard_id)

            for month, score in zip(trend_data["month"], trend_data["score"]):
                key = (person_name, app_leaderboard_name, api_name, month)
                if key not in aggregated_scores:
                    aggregated_scores[key] = {"total_score": 0, "count": 0}

                aggregated_scores[key]["total_score"] += score
                aggregated_scores[key]["count"] += 1

# Create the plot
plt.figure(figsize=(12, 6))  # Adjust the figure size if needed

for (person_name, app_leaderboard_name, api_name, month), data in aggregated_scores.items():
    average_score = data["total_score"] / data["count"]
    plt.plot(month, average_score, marker='o', label=f"{person_name} - {app_leaderboard_name} - {api_name}")

plt.xlabel('Month')
plt.ylabel('Average Score')
plt.title('API Trends Average Score Comparison')
plt.grid(True)
plt.xticks(rotation=45)
plt.legend()
plt.tight_layout()

# Show the plot
plt.show()
