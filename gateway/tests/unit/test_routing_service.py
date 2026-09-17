import pytest

from apex_ai_router.domain.errors import RoutingError
from apex_ai_router.domain.model_target import RoutingConfig
from apex_ai_router.routing.service import RoutingService


def _config(**overrides) -> RoutingConfig:
    data = {
        "routes": {
            "apex-efficient": {"strategy": "fixed", "target": "efficient"},
            "apex-auto": {
                "strategy": "llm_classifier",
                "switchyard_target": "switchyard",
                "efficient_target": "efficient",
                "capable_target": "capable",
                "judge_target": "judge",
                "threshold": 0.5,
            },
        },
        "targets": {
            "efficient": {
                "provider": "openai_compatible",
                "model": "mock-efficient",
                "base_url": "http://example.test",
            },
            "capable": {
                "provider": "openai_compatible",
                "model": "mock-capable",
                "base_url": "http://example.test",
            },
            "judge": {
                "provider": "openai_compatible",
                "model": "mock-judge",
                "base_url": "http://example.test",
            },
            "switchyard": {
                "provider": "switchyard",
                "model": "apex-auto",
                "base_url": "http://localhost:4000",
            },
        },
    }
    data.update(overrides)
    return RoutingConfig.model_validate(data)


def test_resolves_fixed_route():
    service = RoutingService(_config())

    resolved = service.resolve("apex-efficient")

    assert resolved.name == "efficient"
    assert resolved.policy == "fixed"
    assert resolved.config.model == "mock-efficient"


def test_unknown_model_raises_route_not_found():
    service = RoutingService(_config())

    with pytest.raises(RoutingError) as exc_info:
        service.resolve("does-not-exist")

    assert exc_info.value.code == "route_not_found"


def test_llm_classifier_resolves_to_switchyard_target():
    service = RoutingService(_config())

    resolved = service.resolve("apex-auto")

    assert resolved.name == "switchyard"
    assert resolved.policy == "llm_classifier"
    assert resolved.config.provider == "switchyard"
    assert resolved.config.model == "apex-auto"


def test_llm_classifier_without_switchyard_target_raises_routing_failed():
    config = _config(
        routes={
            "apex-auto": {
                "strategy": "llm_classifier",
                "efficient_target": "efficient",
                "capable_target": "capable",
            }
        }
    )
    service = RoutingService(config)

    with pytest.raises(RoutingError) as exc_info:
        service.resolve("apex-auto")

    assert exc_info.value.code == "routing_failed"
    assert "switchyard_target" in exc_info.value.message


def test_llm_classifier_with_wrong_provider_target_raises_routing_failed():
    config = _config(
        routes={
            "apex-auto": {
                "strategy": "llm_classifier",
                "switchyard_target": "efficient",
            }
        }
    )
    service = RoutingService(config)

    with pytest.raises(RoutingError) as exc_info:
        service.resolve("apex-auto")

    assert exc_info.value.code == "routing_failed"
    assert "must use provider 'switchyard'" in exc_info.value.message


def test_fixed_route_with_missing_target_raises_routing_failed():
    config = _config(
        routes={"apex-broken": {"strategy": "fixed", "target": "ghost"}},
        targets={
            "efficient": {
                "provider": "openai_compatible",
                "model": "mock-efficient",
                "base_url": "http://example.test",
            }
        },
    )
    service = RoutingService(config)

    with pytest.raises(RoutingError) as exc_info:
        service.resolve("apex-broken")

    assert exc_info.value.code == "routing_failed"
