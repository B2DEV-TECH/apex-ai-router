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
                "efficient_target": "efficient",
                "capable_target": "capable",
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


def test_llm_classifier_raises_routing_failed_until_phase_3():
    service = RoutingService(_config())

    with pytest.raises(RoutingError) as exc_info:
        service.resolve("apex-auto")

    assert exc_info.value.code == "routing_failed"
    assert "apex-efficient" in exc_info.value.message


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
