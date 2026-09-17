"""OpenAI-compatible response model for `/v1/chat/completions` (spec section 6).

Provider responses are parsed into this shape before being returned to the
client, so a client always gets a stable, validated contract regardless of
which upstream produced it. Unknown provider-specific fields are ignored
rather than rejected.
"""

from pydantic import BaseModel, ConfigDict


class ChatCompletionChoiceMessage(BaseModel):
    model_config = ConfigDict(extra="ignore")

    role: str
    content: str | None = None
    tool_calls: list[dict] | None = None


class ChatCompletionChoice(BaseModel):
    model_config = ConfigDict(extra="ignore")

    index: int
    message: ChatCompletionChoiceMessage
    finish_reason: str | None = None


class ChatCompletionUsage(BaseModel):
    model_config = ConfigDict(extra="ignore")

    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


class ChatCompletionResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: list[ChatCompletionChoice]
    usage: ChatCompletionUsage | None = None


class ErrorBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    code: str
    message: str
    request_id: str


class ErrorResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    error: ErrorBody
