from abc import ABC
from enum import Enum
from typing import *


class SrcPosition:
    def __init__(self, path: str, line: int):
        self.path = path
        self.line = line

    def move_next(self):
        return SrcPosition(path=self.path, line=self.line + 1)

    def is_first(self) -> bool:
        return self.line == 1

    def raise_syntax_error(self, rule: str, hint: str, **kwargs: Any):
        raise MacroError(MacroErrorReason.SYNTAX, self, rule=rule, hint=hint, **kwargs)

    def raise_expression_error(self, error: Union[BaseException, str], **kwargs: Any):
        raise MacroError(MacroErrorReason.EXPRESSION, self, error=error, **kwargs)


class SrcConfig:
    def __init__(self, path: str, encoding: str, macro_sign: str, macro_param_prefix: str):
        self.path = path
        self.encoding = encoding
        self.macro_sign = macro_sign
        self.macro_sign_len = len(self.macro_sign)
        self.macro_param_prefix = macro_param_prefix
        self.macro_param_prefix_len = len(self.macro_param_prefix)


class OutConfig:
    def __init__(self, path: str, encoding: str, newline: str, macro_keep: bool, macro_sign: str):
        self.path = path
        self.encoding = encoding
        self.newline = newline
        self.macro_keep = macro_keep
        self.macro_sign = macro_sign


class MacroErrorReason(Enum):
    SYNTAX = 1,
    EXPRESSION = 2,

    def __str__(self):
        return self.name


class MacroError(Exception):
    def __init__(self, reason: MacroErrorReason, src_position: SrcPosition, **kwargs: Any):
        super().__init__(MacroError._build_message(reason, src_position, **kwargs))
        self.reason = reason

    @staticmethod
    def _build_message(reason: MacroErrorReason, src_position: SrcPosition, **kwargs: Any) -> str:
        items: List[str] = [
            '%s=[%s]' % ('reason', reason),
            '%s=[%s]' % ('path', src_position.path),
            '%s=[%s]' % ('line', src_position.line),
        ]
        for key in kwargs:
            items.append('%s=[%s]' % (key, kwargs[key]))
        return 'Macro Error: %s' % ', '.join(items)


class MacroEnv:
    def __init__(self, variables: Dict[str, Union[str, int]]):
        self.variables = variables

    def eval_condition(self, expression) -> bool:
        return bool(eval(expression, self.variables))

    def has_variable(self, variable: str) -> bool:
        return variable in self.variables

    def get_variable(self, variable: str) -> Union[str, int]:
        return self.variables[variable]


class Macro(ABC):
    def __init__(self, env: MacroEnv, content: str, src_position: SrcPosition, out_template: str):
        self.env = env
        self.content = content
        self.src_position = src_position
        self.out_template = out_template


class MacroParam(Macro):
    def __init__(self, macro: Macro, key: str, value: str):
        super().__init__(macro.env, macro.content, macro.src_position, macro.out_template)
        self.name = key
        self.value = value
