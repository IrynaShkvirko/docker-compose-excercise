test_results = [
    {"name": "test_login", "status": "passed", "duration": 1.2},
    {"name": "test_signup", "status": "failed", "duration": 2.5},
    {"name": "test_logout", "status": "passed", "duration": 0.8},
    {"name": "test_payment", "status": "failed", "duration": 3.1},
    {"name": "test_profile", "status": "passed", "duration": 1.5},
    {"name": "test_search", "status": "skipped", "duration": 0.0},
    {"name": "test_checkout", "status": "passed", "duration": 4.2},
]

def analyze_test_results(results: list[dict]) -> dict:
    analyzed_tests = {
        "total": len(results),
        "status_counts": {},
        "failed_tests": [],
        "average_duration": 0,
        "slowest_test": None,
    }
    slowest_duration = None
    total_duration = 0

    for result in results:
        analyzed_tests["status_counts"][result["status"]] = analyzed_tests["status_counts"].get(result["status"], 0) + 1
        if result["status"] == "failed":
            analyzed_tests["failed_tests"].append(result["name"])
        duration = result["duration"]
        total_duration += duration
        if slowest_duration is None or duration > slowest_duration:
            analyzed_tests["slowest_test"] = result["name"]
            slowest_duration = duration
    if analyzed_tests["total"]:
        analyzed_tests["average_duration"] = round(
            total_duration / analyzed_tests["total"], 2
        )
    return analyzed_tests


print(analyze_test_results(test_results))

# It should return a dictionary containing:
# 1. total — total number of tests.
# 2. status_counts — number of tests grouped by status.
# 3. failed_tests — list of names of failed tests.
# 4. average_duration — average duration across all tests, rounded to two decimal places.
# 5. slowest_test — name of the test with the longest duration.

api_logs = [
    {"endpoint": "/users", "method": "GET", "status": 200, "response_time": 120},
    {"endpoint": "/users", "method": "POST", "status": 201, "response_time": 250},
    {"endpoint": "/orders", "method": "GET", "status": 500, "response_time": 800},
    {"endpoint": "/users", "method": "GET", "status": 200, "response_time": 100},
    {"endpoint": "/orders", "method": "POST", "status": 400, "response_time": 350},
    {"endpoint": "/products", "method": "GET", "status": 200, "response_time": 180},
    {"endpoint": "/orders", "method": "GET", "status": 200, "response_time": 600},
]

def analyze_api_logs(logs: list[dict]) -> dict:
    analyzed_logs = {
        "total_requests": len(logs),
        "requests_per_endpoint": {},
        "failed_requests": [],
        "average_response_time": 0,
        "slow_endpoints": [],
        "most_requested_endpoint": None,
    }
    total_response_time = 0
    seen_slow = set()
    for log in logs:
        endpoint = log["endpoint"]
        analyzed_logs["requests_per_endpoint"][endpoint] = analyzed_logs["requests_per_endpoint"].get(endpoint, 0) + 1
        if log["status"] >= 400:
            analyzed_logs["failed_requests"].append(endpoint)
        total_response_time += log["response_time"]
        if log["response_time"] > 500 and endpoint not in seen_slow:
            seen_slow.add(endpoint)
            analyzed_logs["slow_endpoints"].append(endpoint)
        current = analyzed_logs["most_requested_endpoint"]
        if current is None or analyzed_logs["requests_per_endpoint"][endpoint] > analyzed_logs["requests_per_endpoint"][current]:
            analyzed_logs["most_requested_endpoint"] = endpoint
    if analyzed_logs["total_requests"]:
        analyzed_logs["average_response_time"] = round(
            total_response_time / analyzed_logs["total_requests"], 2
        )
    return analyzed_logs

print(analyze_api_logs(api_logs))

# Your function should return:
# 1. total_requests — total number of requests.
# 2. requests_per_endpoint — number of requests grouped by endpoint.
# 3. failed_requests — endpoints of requests with status codes >= 400, preserving duplicates and input order.
# 4. average_response_time — average response time across all requests, rounded to two decimals.
# 5. slow_endpoints — unique endpoint names where at least one request took more than 500 ms, preserving first-occurrence order.
# 6. most_requested_endpoint — endpoint with the highest number of requests. In a tie, return the endpoint encountered first.

test_executions = [
    {"suite": "api", "test": "login", "status": "passed", "duration": 1.2},
    {"suite": "api", "test": "signup", "status": "failed", "duration": 2.5},
    {"suite": "ui", "test": "checkout", "status": "passed", "duration": 5.0},
    {"suite": "api", "test": "logout", "status": "passed", "duration": 0.8},
    {"suite": "ui", "test": "payment", "status": "failed", "duration": 6.2},
    {"suite": "integration", "test": "database", "status": "passed", "duration": 3.5},
    {"suite": "ui", "test": "search", "status": "skipped", "duration": 0.0},
    {"suite": "integration", "test": "queue", "status": "failed", "duration": 4.1},
]

from collections import defaultdict


def aggregate_test_suites(executions: list[dict]) -> dict:
    # defaultdict creates the suite entry on first access,
    # replacing the `if suite not in aggregated_suites` block
    aggregated_suites = defaultdict(
        lambda: {
            "total": 0,
            "passed": 0,
            "failed": 0,
            "average_duration": 0,
            "failed_tests": [],
        }
    )
    # Separate sums, so "average_duration" only ever means an average
    duration_sums = defaultdict(float)

    for execution in executions:
        suite = execution["suite"]
        stats = aggregated_suites[suite]

        stats["total"] += 1
        duration_sums[suite] += execution["duration"]

        if execution["status"] == "passed":
            stats["passed"] += 1
        elif execution["status"] == "failed":
            stats["failed"] += 1
            stats["failed_tests"].append(execution["test"])

    for suite, stats in aggregated_suites.items():
        stats["average_duration"] = round(duration_sums[suite] / stats["total"], 2)

    # Convert back to a plain dict so callers don't get defaultdict behavior
    return dict(aggregated_suites)

print(aggregate_test_suites(test_executions))


# {
#     "api": {
#         "total": 3,
#         "passed": 2,
#         "failed": 1,
#         "average_duration": 1.5,
#         "failed_tests": ["signup"]
#     },
#     "ui": {
#         "total": 3,
#         "passed": 1,
#         "failed": 1,
#         "average_duration": 3.73,
#         "failed_tests": ["payment"]
#     },
#     "integration": {
#         "total": 2,
#         "passed": 1,
#         "failed": 1,
#         "average_duration": 3.8,
#         "failed_tests": ["queue"]
#     }
# }
source = [
    {"id": 1, "name": "Alice", "email": "alice@test.com", "status": "active"},
    {"id": 2, "name": "Bob", "email": "bob@test.com", "status": "active"},
    {"id": 3, "name": "Charlie", "email": "charlie@test.com", "status": "inactive"},
    {"id": 4, "name": "Diana", "email": "diana@test.com", "status": "active"},
]

target = [
    {"id": 1, "name": "Alice", "email": "alice@test.com", "status": "active"},
    {"id": 2, "name": "Bob", "email": "bob.new@test.com", "status": "active"},
    {"id": 3, "name": "Charlie", "email": "charlie@test.com", "status": "active"},
    {"id": 5, "name": "Eve", "email": "eve@test.com", "status": "active"},
]

def compare_records(source: list[dict], target: list[dict]) -> dict:
    comparison = {
        "missing_in_target": [],
        "extra_in_target": [],
        "modified_records": {},
        "unchanged_records": [],
    }
    source_dict = {record["id"]: record for record in source}
    target_dict = {record["id"]: record for record in target}
    for record in source:
        record_id = record["id"]
        if record_id not in target_dict:
            comparison["missing_in_target"].append(record_id)
            continue
        target_record = target_dict[record_id]
        changes = {}
        fields = list(record.keys())
        for field in target_record:
            if field not in fields:
                fields.append(field)
        for field in fields:
            if field == "id":
                continue
            if record.get(field) != target_record.get(field):
                changes[field] = {
                    "source": record.get(field),
                    "target": target_record.get(field),
                }
        if changes:
            comparison["modified_records"][record_id] = changes
        else:
            comparison["unchanged_records"].append(record_id)
    for record in target:
        if record["id"] not in source_dict:
            comparison["extra_in_target"].append(record["id"])
    return comparison

# With lists, how would you find the record with id == 2? How expensive is that if you do it for every record?
# What data structure gives you “give me the record for this id” instantly? What would the keys and values be?

print(compare_records(source, target))


# {
#     "missing_in_target": [4],
#     "extra_in_target": [5],
#     "modified_records": {
#         2: {
#             "email": {
#                 "source": "bob@test.com",
#                 "target": "bob.new@test.com"
#             }
#         },
#         3: {
#             "status": {
#                 "source": "inactive",
#                 "target": "active"
#             }
#         }
#     },
#     "unchanged_records": [1]
# }