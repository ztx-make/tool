from command import *


class _SrcFormat(Enum):
    OTHER = 1,
    XML = 2,

    def __str__(self):
        return self.name


class SrcParser:
    def __init__(self, macro_env: MacroEnv, src_config: SrcConfig):
        self.macro_env = macro_env
        self.src_config = src_config
        self.src_position = SrcPosition(src_config.path, 0)
        self.src_format = _SrcFormat.XML if src_config.path.lower().endswith('.xml') else _SrcFormat.OTHER
        self.current_command: Optional[MacroCommand] = None

    def parse_element(self, line: str, current_command: Optional[MacroCommand]) -> Union[MacroParam, MacroCommand, str]:
        self.src_position = self.src_position.move_next()
        self.current_command = current_command
        element = self._parse_element(line)
        self._check_parsed_element(element)
        return element

    def _parse_element(self, line: str) -> Union[MacroParam, MacroCommand, str]:
        trimmed_line = line.strip()
        if self.src_position.line < 3 and '<?xml ' in trimmed_line and '?>' in trimmed_line:
            self.src_format = _SrcFormat.XML

        macro_line = None
        out_template = None
        two_end_comment = False
        if trimmed_line.startswith('//'):
            macro_line = trimmed_line[2:]
            out_template = '// %s %s'
        elif trimmed_line.startswith('#'):
            macro_line = trimmed_line[1:]
            out_template = '# %s %s'
        elif trimmed_line.startswith(';'):
            macro_line = trimmed_line[1:]
            out_template = '; %s %s'
        elif trimmed_line.startswith('<!--') and trimmed_line.endswith('-->'):
            macro_line = trimmed_line[4:-3]
            out_template = '<!-- %s %s -->'
            two_end_comment = True

        if not macro_line:
            return line

        sign_index = macro_line.find(self.src_config.macro_sign)
        if sign_index < 0:
            return line

        self._check_macro_line_syntax(line, trimmed_line, macro_line, sign_index, two_end_comment)

        if two_end_comment:
            macro_line = macro_line[1:-1]
        else:
            macro_line = macro_line[1:]

        macro_content = macro_line[self.src_config.macro_sign_len + 1:]
        macro = Macro(self.macro_env, macro_content, self.src_position, out_template)

        colon_index = macro_content.find(':')
        if colon_index < 0:
            return self._parse_macro_command_without_expression(macro, macro_content)

        self._check_macro_content_syntax(macro_content, colon_index)

        if not macro_content.startswith(self.src_config.macro_param_prefix):
            return self._parse_macro_command(macro, colon_index)
        else:
            return self._parse_macro_param(macro, colon_index)

    def _parse_macro_command(self, macro: Macro, colon_index: int) -> MacroCommand:
        content = macro.content
        command = content[:colon_index]
        expression = content[colon_index + 2:]

        self._check_macro_command_syntax(macro, command, expression)

        matched = False
        try:
            matched = self.macro_env.eval_condition(expression)
        except BaseException as error:
            self.src_position.raise_expression_error(error)

        return MacroCommandFactory.create(macro, command, matched)

    def _parse_macro_command_without_expression(self, macro: Macro, macro_content: str) -> MacroCommand:
        if MacroCommandFactory.is_fallback(macro_content):
            if self.current_command:
                return MacroCommandFactory.create(macro, macro_content, not self.current_command.matched)
            else:
                return MacroCommandFactory.create(macro, macro_content, False)
        else:
            return MacroCommandFactory.create(macro, macro_content, True)

    def _parse_macro_param(self, macro: Macro, colon_index: int) -> MacroParam:
        content = macro.content
        self._check_macro_param_syntax(content, colon_index)
        name = content[self.src_config.macro_param_prefix_len:colon_index]
        value = content[colon_index + 2:]
        if len(value) > 1:
            self._check_macro_param_value_syntax(value)
            if value.startswith('`') and value.endswith('`'):
                value = value[1:-1]

        if self.current_command:
            self.current_command.options.check_raw_param(macro, name, value)

        return MacroParam(macro, name, value)

    def _check_macro_line_syntax(
            self, line: str, trimmed_line: str, macro_line: str, sign_index: int, two_end_comment: bool
    ):
        if len(line) != len(trimmed_line) and len(line) - 1 != len(trimmed_line):
            self.src_position.raise_syntax_error('PARSER_A1', '行内有多余的空格')
        if macro_line[0] != ' ':
            self.src_position.raise_syntax_error('PARSER_A2', '宏标记前缺少空格')
        if sign_index != 1:
            self.src_position.raise_syntax_error('PARSER_A3', '宏标记前有多余的内容')
        if len(macro_line) == self.src_config.macro_sign_len + 1:
            self.src_position.raise_syntax_error('PARSER_A4', '宏标记后缺少内容')
        if macro_line[self.src_config.macro_sign_len + 1] != ' ':
            self.src_position.raise_syntax_error('PARSER_A5', '宏标记后缺少空格')
        if macro_line[self.src_config.macro_sign_len + 2] == ' ':
            self.src_position.raise_syntax_error('PARSER_A6', '宏标记后有多余的空格')
        if two_end_comment and macro_line[-1] != ' ':
            self.src_position.raise_syntax_error('PARSER_A7', '宏结尾处缺少空格')
        if two_end_comment and macro_line[-2] == ' ':
            self.src_position.raise_syntax_error('PARSER_A8', '宏结尾处有多余的空格')

    def _check_macro_content_syntax(self, macro_content: str, colon_index: int):
        if colon_index == 0:
            self.src_position.raise_syntax_error('PARSER_B1', '缺少宏命令或宏参数')
        if macro_content[colon_index + 1] != ' ':
            self.src_position.raise_syntax_error('PARSER_B2', '宏命令或宏参数后缺少空格')
        if macro_content[colon_index + 2] == ' ':
            self.src_position.raise_syntax_error('PARSER_B3', '宏命令或宏参数后有多余的空格')

    def _check_macro_command_syntax(self, macro: Macro, command: str, expression: str):
        if MacroCommandFactory.is_fallback(command):
            self.src_position.raise_syntax_error('PARSER_C1', '宏命令fallback不能有条件表达式')
        if MacroCommandFactory.is_end(command):
            self.src_position.raise_syntax_error('PARSER_C2', '宏命令end不能有条件表达式')

    def _check_macro_param_syntax(self, macro: str, colon_index: int):
        if ' ' in macro[self.src_config.macro_param_prefix_len:colon_index]:
            self.src_position.raise_syntax_error('PARSER_D1', '宏参数名不能有空格')

    def _check_macro_param_value_syntax(self, value: str):
        if value.startswith('`') and not value.endswith('`'):
            self.src_position.raise_syntax_error('PARSER_E1', '宏参数值的反引号不成对')
        if not value.startswith('`') and value.endswith('`'):
            self.src_position.raise_syntax_error('PARSER_E2', '宏参数值的反引号不成对')

    def _check_parsed_element(self, element: Union[MacroParam, MacroCommand, str]):
        if self.src_format != _SrcFormat.XML:
            if self.src_position.is_first() and not isinstance(element, FileMacroCommand):
                self.src_position.raise_syntax_error('PARSER_F1', '首行必须为宏命令file')
            if not self.src_position.is_first() and isinstance(element, FileMacroCommand):
                self.src_position.raise_syntax_error('PARSER_F2', '宏命令file必须在首行')
        if isinstance(element, MacroParam):
            if self.current_command is None:
                self.src_position.raise_syntax_error('PARSER_F3', '宏参数必须在宏命令下')
        if isinstance(element, EndMacroCommand):
            if not isinstance(self.current_command, BlockMacroCommand):
                self.src_position.raise_syntax_error('PARSER_F4', '宏命令end必须在块级宏命令之后')
        if isinstance(element, FallbackMacroCommand):
            is_insert = type(self.current_command) == InsertMacroCommand
            is_template = type(self.current_command) == TemplateMacroCommand
            if not is_insert and not is_template:
                self.src_position.raise_syntax_error('PARSER_F5',
                                                     '宏命令fallback必须在宏命令insert或宏命令template之后')
        if self.src_format == _SrcFormat.XML:
            self._check_parsed_element_xml(element)

    def _check_parsed_element_xml(self, element: Union[MacroParam, MacroCommand, str]):
        if self.src_position.line != 2 and isinstance(element, FileMacroCommand):
            self.src_position.raise_syntax_error('PARSER_G1', 'XML文件宏命令file必须在第二行')
        if self.src_position.line == 2 and not isinstance(element, FileMacroCommand):
            self.src_position.raise_syntax_error('PARSER_G2', 'XML文件第二行必须为宏命令file')
