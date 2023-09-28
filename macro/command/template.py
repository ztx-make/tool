from .base import *


class _TemplateVariablesOption(MacroCommandOption):
    def check_raw_value(self, macro: Macro, value: str):
        super().check_raw_value(macro, value)
        variables = [var for var in value.split(',')]
        index = 0
        for var in variables:
            trimmed = var.strip()
            if len(trimmed) == 0:
                macro.src_position.raise_syntax_error('TEMPLATE_1', '参数值有多余的逗号', param=self.name, value=value)
            if index == 0 and len(var) != len(trimmed):
                macro.src_position.raise_syntax_error('TEMPLATE_2', '参数值之间有多余的空格', param=self.name,
                                                      value=value)
            if index != 0 and len(var) - len(trimmed) < 1:
                macro.src_position.raise_syntax_error('TEMPLATE_3', '参数值之间缺少空格', param=self.name, value=value)
            if index != 0 and len(var) - len(trimmed) > 1:
                macro.src_position.raise_syntax_error('TEMPLATE_4', '参数值之间有多余的空格', param=self.name,
                                                      value=value)
            if not macro.env.has_variable(trimmed):
                macro.src_position.raise_expression_error('variable %s not found' % trimmed)
            index += 1

    def set_value(self, param: MacroParam):
        if self.value is None:
            self.value: Dict[str, str] = {}
        variables = [var.strip() for var in param.value.split(',')]
        for var in variables:
            self.value[var] = str(param.env.get_variable(var))


class TemplateMacroCommand(BlockMacroCommand):
    PARAM_TEMPLATE_VARIABLES = 'template-variables'

    def __init__(self, macro: Macro, command: str, matched: bool):
        super().__init__(macro, command, matched)
        self.options.add_option(_TemplateVariablesOption(TemplateMacroCommand.PARAM_TEMPLATE_VARIABLES, True))
        self.param_template_variables: Optional[Dict[str, str]] = None

    def apply_options(self):
        super().apply_options()
        self.param_template_variables = self.options.get_value(TemplateMacroCommand.PARAM_TEMPLATE_VARIABLES)

    def _build_out(self, builder: MacroCommandOutBuilder):
        super()._build_out(builder)
        if self.matched:
            inject_count = 0
            lines: List[str] = []
            for line in self.lines:
                for var in self.param_template_variables:
                    search = '@%s@' % var
                    while search in line:
                        line = line.replace(search, self.param_template_variables[var], 1)
                        inject_count += 1
                lines.append(line)
            builder.append_result(matched=self.matched, inject_count=inject_count)
            builder.append_lines(lines)
        else:
            builder.append_result(matched=self.matched, drop_lines=len(self.lines))
