from base import *


class MacroCommandOption(ABC):
    def __init__(self, name: str, required: bool, allow_duplicate: bool = False):
        self.name = name
        self.required = required
        self.allow_duplicate = allow_duplicate
        self.value: Any = None

    def check_raw_value(self, macro: Macro, value: str):
        if not self.allow_duplicate and self.value is not None:
            macro.src_position.raise_syntax_error('OPTION_1', '参数重复', param=self.name)

    def set_value(self, param: MacroParam):
        raise NotImplemented

    def check_value(self, macro: Macro):
        if self.required and self.value is None:
            macro.src_position.raise_syntax_error('OPTION_2', '缺少参数', param=self.name)


class MacroCommandOptions:
    def __init__(self, macro: Macro):
        self.macro = macro
        self.options: Dict[str, MacroCommandOption] = {}
        self.params: List[MacroParam] = []

    def add_option(self, option: MacroCommandOption):
        self.options[option.name] = option

    def get_value(self, name: str) -> Any:
        option = self.options[name]
        option.check_value(self.macro)
        return option.value

    def set_param(self, param: MacroParam):
        self.options[param.name].set_value(param)
        self.params.append(param)

    def check_raw_param(self, macro: Macro, name: str, value: str):
        if name not in self.options:
            macro.src_position.raise_syntax_error('OPTIONS_1', '未知参数', param=name)
        self.options[name].check_raw_value(macro, value)
