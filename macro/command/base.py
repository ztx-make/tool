from base import *
from option import *


class MacroCommand(Macro, ABC):
    PARAM_OUT_MACRO_KEEP = 'out-macro-keep'
    PARAM_OUT_MACRO_SIGN = 'out-macro-sign'

    def __init__(self, macro: Macro, command: str, matched: bool):
        super().__init__(macro.env, macro.content, macro.src_position, macro.out_template)
        self.command = command
        self.matched = matched
        self.options = MacroCommandOptions(self)
        self.options.add_option(BoolMacroCommandOption(MacroCommand.PARAM_OUT_MACRO_KEEP, False))
        self.options.add_option(StringMacroCommandOption(MacroCommand.PARAM_OUT_MACRO_SIGN, False))
        self.param_out_macro_keep: Optional[bool] = None
        self.param_out_macro_sign: Optional[str] = None

    def apply_options(self):
        self.param_out_macro_keep = self.options.get_value(MacroCommand.PARAM_OUT_MACRO_KEEP)
        self.param_out_macro_sign = self.options.get_value(MacroCommand.PARAM_OUT_MACRO_SIGN)

    def out(self, out_config: OutConfig) -> List[str]:
        builder = MacroCommandOutBuilder(self, out_config)
        self._build_out(builder)
        return builder.build()

    def _build_out(self, builder: 'MacroCommandOutBuilder'):
        builder.append_command()
        builder.append_params()


class BlockMacroCommand(MacroCommand, ABC):
    def __init__(self, macro: Macro, command: str, matched: bool):
        super().__init__(macro, command, matched)
        self.lines: List[str] = []

    def append_line(self, line: str):
        self.lines.append(line)


class MacroCommandOutConfig:
    def __init__(self, out_config: OutConfig, macro_keep: Optional[bool], macro_sign: Optional[str]):
        if macro_keep is not None:
            self.macro_keep = macro_keep
        else:
            self.macro_keep = out_config.macro_keep

        if macro_sign is not None:
            self.macro_sign = macro_sign
        else:
            self.macro_sign = out_config.macro_sign


class MacroCommandOutBuilder:
    def __init__(self, command: MacroCommand, out_config: OutConfig):
        self.command = command
        self.template = command.out_template
        self.config = MacroCommandOutConfig(out_config, command.param_out_macro_keep, command.param_out_macro_sign)
        self.result: List[str] = []

    def _format_macro(self, macro: str) -> str:
        return self.template % (self.config.macro_sign, macro)

    def append_command(self):
        if self.config.macro_keep:
            self.result.append(self._format_macro(self.command.content))

    def append_params(self):
        if self.config.macro_keep:
            self.result.extend([self._format_macro(param.content) for param in self.command.options.params])

    def append_result(self, **kwargs: Any):
        if self.config.macro_keep:
            key_value: List[str] = []
            for key in kwargs:
                key_value.append('%s: %s' % (key.replace('_', '-'), kwargs[key]))
            self.result.append(self._format_macro('result %s' % ('; '.join(key_value))))

    def append_lines(self, lines: List[str]):
        self.result.extend(lines)

    def build(self):
        return self.result
