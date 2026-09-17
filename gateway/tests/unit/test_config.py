from apex_ai_router.config import Settings


def test_defaults():
    settings = Settings(_env_file=None)
    assert settings.environment == "development"
    assert settings.port == 8080
    assert settings.api_key_list == []


def test_api_key_list_parses_comma_separated_and_trims():
    settings = Settings(_env_file=None, api_keys="a, b ,c")
    assert settings.api_key_list == ["a", "b", "c"]


def test_api_key_list_empty_string_is_empty_list():
    settings = Settings(_env_file=None, api_keys="")
    assert settings.api_key_list == []
