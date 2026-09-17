import pytest
from pydantic import ValidationError

from apex_ai_router.domain.request import ChatCompletionRequest


def test_valid_request_round_trips():
    request = ChatCompletionRequest(
        model="apex-efficient",
        messages=[{"role": "user", "content": "hello"}],
        temperature=0.7,
    )
    assert request.model == "apex-efficient"
    assert request.messages[0].role == "user"
    assert request.stream is False


def test_rejects_unknown_top_level_field():
    with pytest.raises(ValidationError):
        ChatCompletionRequest(
            model="apex-efficient",
            messages=[{"role": "user", "content": "hi"}],
            frequency_penalty=0.5,
        )


def test_rejects_empty_messages():
    with pytest.raises(ValidationError):
        ChatCompletionRequest(model="apex-efficient", messages=[])


def test_rejects_invalid_role():
    with pytest.raises(ValidationError):
        ChatCompletionRequest(
            model="apex-efficient",
            messages=[{"role": "narrator", "content": "hi"}],
        )


def test_rejects_temperature_out_of_range():
    with pytest.raises(ValidationError):
        ChatCompletionRequest(
            model="apex-efficient",
            messages=[{"role": "user", "content": "hi"}],
            temperature=5,
        )
