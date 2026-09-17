import tomllib

import pytest

from apex_ai_router.domain.model_target import RoutingConfig
from apex_ai_router.routing.switchyard_config import render_routes_toml


def _config(**route_overrides) -> RoutingConfig:
    route = {
        "strategy": "llm_classifier",
        "switchyard_target": "switchyard",
        "efficient_target": "efficient",
        "capable_target": "capable",
        "judge_target": "judge",
        "threshold": 0.5,
    }
    route.update(route_overrides)
    return RoutingConfig.model_validate(
        {
            "routes": {"apex-auto": route},
            "targets": {
                "efficient": {
                    "provider": "openai_compatible",
                    "model": "small-model",
                    "base_url": "https://api.example.com",
                    "api_key_env": "EFFICIENT_MODEL_API_KEY",
                },
                "capable": {
                    "provider": "openai_compatible",
                    "model": "big-model",
                    "base_url": "https://api.example.com",
                    "api_key_env": "CAPABLE_MODEL_API_KEY",
                },
                "judge": {
                    "provider": "openai_compatible",
                    "model": "small-model",
                    "base_url": "https://api.example.com",
                    "api_key_env": "JUDGE_MODEL_API_KEY",
                },
                "switchyard": {
                    "provider": "switchyard",
                    "model": "apex-auto",
                    "base_url": "http://localhost:4000",
                },
            },
        }
    )


def test_renders_valid_toml_with_expected_structure():
    toml_text = render_routes_toml(_config())
    parsed = tomllib.loads(toml_text)

    assert parsed["schema_version"] == 1

    assert parsed["llm_clients"]["efficient"]["format"] == "openai_chat"
    # TargetConfig.base_url is a bare host root everywhere else in this
    # gateway; Switchyard's openai_chat client needs the `/v1` appended.
    assert parsed["llm_clients"]["efficient"]["base_url"] == "https://api.example.com/v1"
    assert parsed["llm_clients"]["efficient"]["api_key_env"] == "EFFICIENT_MODEL_API_KEY"

    assert parsed["targets"]["efficient"] == {"id": "small-model", "llm_client": "efficient"}
    assert parsed["targets"]["capable"] == {"id": "big-model", "llm_client": "capable"}
    assert parsed["targets"]["judge"] == {"id": "small-model", "llm_client": "judge"}

    route = parsed["routes"]["apex-auto"]
    assert route["id"] == "apex-auto"
    assert route["type"] == "llm_classifier"
    assert route["mode"] == "capability"
    assert route["classifier_target"] == "judge"
    assert route["strong_target"] == "capable"
    assert route["weak_target"] == "efficient"
    assert route["base_threshold"] == 0.5


def test_appends_v1_without_double_slash_when_base_url_has_trailing_slash():
    config = _config()
    config.targets["efficient"].base_url = "https://api.example.com/"

    toml_text = render_routes_toml(config)
    parsed = tomllib.loads(toml_text)

    assert parsed["llm_clients"]["efficient"]["base_url"] == "https://api.example.com/v1"


def test_defaults_threshold_to_half_when_unset():
    toml_text = render_routes_toml(_config(threshold=None))
    parsed = tomllib.loads(toml_text)

    assert parsed["routes"]["apex-auto"]["base_threshold"] == 0.5


def test_omits_api_key_env_when_target_has_none():
    config = _config()
    config.targets["efficient"].api_key_env = None

    toml_text = render_routes_toml(config)
    parsed = tomllib.loads(toml_text)

    assert "api_key_env" not in parsed["llm_clients"]["efficient"]


def test_escapes_quotes_and_backslashes_in_values():
    config = _config()
    config.targets["efficient"].model = 'weird"model\\name'

    toml_text = render_routes_toml(config)
    parsed = tomllib.loads(toml_text)

    assert parsed["targets"]["efficient"]["id"] == 'weird"model\\name'


def test_unknown_route_raises_value_error():
    with pytest.raises(ValueError, match="Unknown route"):
        render_routes_toml(_config(), route_name="does-not-exist")


def test_non_llm_classifier_route_raises_value_error():
    config = RoutingConfig.model_validate(
        {
            "routes": {"apex-efficient": {"strategy": "fixed", "target": "efficient"}},
            "targets": {
                "efficient": {
                    "provider": "openai_compatible",
                    "model": "small-model",
                    "base_url": "https://api.example.com/v1",
                }
            },
        }
    )

    with pytest.raises(ValueError, match="not an llm_classifier route"):
        render_routes_toml(config, route_name="apex-efficient")


def test_missing_judge_target_raises_value_error():
    with pytest.raises(ValueError, match="judge_target"):
        render_routes_toml(_config(judge_target=None))
