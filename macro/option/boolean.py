from .base import *


class BoolMacroCommandOption(MacroCommandOption):
    def check_raw_value(self, macro: Macro, value: str):
        if value not in ('True', 'False'):
            macro.src_position.raise_syntax_error('BOOL_OPTION_1', '布尔值只能是True或False', param=self.name, value=value)

    def set_value(self, param: MacroParam):
        self.value = param.value == 'True'
