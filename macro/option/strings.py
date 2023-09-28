from .base import *


class StringsMacroCommandOption(MacroCommandOption):
    def __init__(self, name: str, required: bool):
        super().__init__(name, required, True)

    def check_raw_value(self, macro: Macro, value: str):
        super().check_raw_value(macro, value)
        if not value:
            macro.src_position.raise_syntax_error('STRINGS_OPTION_1', '字符串值不能为空', param=self.name)

    def set_value(self, param: MacroParam):
        if self.value is None:
            self.value: List[str] = []
        self.value.append(param.value)
