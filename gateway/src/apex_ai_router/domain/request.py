"""OpenAI-compatible request model for `/v1/chat/completions` (spec section 6).

Only the fields this gateway actually understands are declared, and the
model rejects anything else (`extra="forbid"`) instead of silently
dropping unsupported OpenAI parameters.
"""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class ChatMessage(BaseModel):
    model_config = ConfigDict(extra="forbid")

    role: Literal["system", "user", "assistant", "tool"]
    content: str
    name: str | None = None


class ToolFunctionDef(BaseModel):
    model_config = ConfigDict(extra="allow")

    name: str
    description: str | None = None
    parameters: dict | None = None


class ToolDef(BaseModel):
    model_config = ConfigDict(extra="forbid")

    type: Literal["function"]
    function: ToolFunctionDef


class ChatCompletionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    model: str
    messages: list[ChatMessage] = Field(min_length=1)
    temperature: float | None = Field(default=None, ge=0, le=2)
    max_tokens: int | None = Field(default=None, gt=0)
    max_completion_tokens: int | None = Field(default=None, gt=0)
    stream: bool = False
    tools: list[ToolDef] | None = None
    tool_choice: str | dict | None = None
