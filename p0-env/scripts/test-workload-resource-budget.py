#!/usr/bin/env python3
"""Small deterministic contract test for workload resource-budget analysis."""

from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


SCRIPT = Path(__file__).with_name("analyze-workload-resource-budget.py")
spec = spec_from_file_location("resource_budget", SCRIPT)
module = module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

capacity = [
    {"users": 10, "frontend_user_server_span_rate_per_second": 2.0, "recommendationservice_cpu_mean_millicores": 20.0},
    {"users": 15, "frontend_user_server_span_rate_per_second": 3.0, "recommendationservice_cpu_mean_millicores": 30.0},
    {"users": 20, "frontend_user_server_span_rate_per_second": 4.0, "recommendationservice_cpu_mean_millicores": 40.0},
]
profile = {
    "target": {"cpu_limit_millicores": 200},
    "injector": {"target_additional_cpu_millicores": 150},
}
report = "\n".join(
    f"| `ob-cpu-high-00{i}` | 10.000 | 160.000 | {value:.3f} | 59/59 |"
    for i, value in enumerate((145.0, 150.0, 155.0), 1)
)
result = module.analyze(capacity, profile, report)
assert result["interpolation_screen"]["users_at_1_30x_request_rate"] == 13.0
assert result["interpolation_screen"]["estimated_mean_cpu_at_that_point_millicores"] == 26.0
assert result["candidates"]["15"]["max_high_request_with_25m_reserve"] == 145.0
assert result["candidates"]["20"]["minimum_limit_for_150m_request_and_25m_reserve"] == 215.0
print("workload_resource_budget_fixture=passed")
