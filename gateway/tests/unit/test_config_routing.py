import pytest

from apex_ai_router.config import RoutingConfigError, load_routing_config

_VALID_TEMPLATE = """
routes:
  apex-efficient:
    strategy: fixed
    target: efficient
targets:
  efficient:
    provider: openai_compatible
    model: {model}
    base_url: http://example.test
    api_key_env: EFFICIENT_MODEL_API_KEY
"""


def test_load_routing_config_happy_path(tmp_path):
    path = tmp_path / "routing.yaml"
    path.write_text(_VALID_TEMPLATE.format(model="gpt-mock-efficient"), encoding="utf-8")

    config = load_routing_config(path)

    assert config.routes["apex-efficient"].strategy == "fixed"
    assert config.targets["efficient"].model == "gpt-mock-efficient"


def test_load_routing_config_substitutes_env_vars(tmp_path, monkeypatch):
    monkeypatch.setenv("TEST_EFFICIENT_MODEL_ID", "gpt-mock-efficient")
    path = tmp_path / "routing.yaml"
    path.write_text(_VALID_TEMPLATE.format(model="${TEST_EFFICIENT_MODEL_ID}"), encoding="utf-8")

    config = load_routing_config(path)

    assert config.targets["efficient"].model == "gpt-mock-efficient"


def test_load_routing_config_missing_file_raises(tmp_path):
    missing = tmp_path / "nope.yaml"

    with pytest.raises(RoutingConfigError, match="not found"):
        load_routing_config(missing)


def test_load_routing_config_unresolved_placeholder_raises(tmp_path, monkeypatch):
    monkeypatch.delenv("TEST_UNSET_MODEL_ID", raising=False)
    path = tmp_path / "routing.yaml"
    path.write_text(_VALID_TEMPLATE.format(model="${TEST_UNSET_MODEL_ID}"), encoding="utf-8")

    with pytest.raises(RoutingConfigError, match="unresolved placeholder"):
        load_routing_config(path)


def test_load_routing_config_empty_env_var_raises_unresolved_placeholder(tmp_path, monkeypatch):
    """A variable that is *set but empty* (`FOO=` in `.env`) used to substitute
    to an empty string, turning `model: ${FOO}` into YAML `null` and crashing
    with a raw, uncaught `pydantic.ValidationError` (found via a live smoke
    test with an unfilled `JUDGE_MODEL_ID`). It must be treated exactly like
    an unset variable instead."""
    monkeypatch.setenv("TEST_EMPTY_MODEL_ID", "")
    path = tmp_path / "routing.yaml"
    path.write_text(_VALID_TEMPLATE.format(model="${TEST_EMPTY_MODEL_ID}"), encoding="utf-8")

    with pytest.raises(RoutingConfigError, match="unresolved placeholder"):
        load_routing_config(path)


def test_load_routing_config_malformed_shape_raises_routing_config_error(tmp_path):
    """A `routing.yaml` that is malformed independent of any `${VAR}`
    substitution (here: a target missing its required `model` field) used to
    raise a bare `pydantic.ValidationError` straight out of `model_validate`,
    with no try/except anywhere in `load_routing_config` -- bypassing the
    sanitized `RoutingConfigError` handling entirely. It must be re-raised as
    `RoutingConfigError` instead."""
    path = tmp_path / "routing.yaml"
    path.write_text(
        """
routes:
  apex-efficient:
    strategy: fixed
    target: efficient
targets:
  efficient:
    provider: openai_compatible
    base_url: http://example.test
""",
        encoding="utf-8",
    )

    with pytest.raises(RoutingConfigError, match="Invalid routing config"):
        load_routing_config(path)
