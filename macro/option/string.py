from .base import *


class StringMacroCommandOption(MacroCommandOption):
    def check_raw_value(self, macro: Macro, value: str):
        super().check_raw_value(macro, value)
        if not value:
            macro.src_position.raise_syntax_error('STRING_OPTION_1', '字符串值不能为空', param=self.name)

    def set_value(self, param: MacroParam):
        self.value = param.value
