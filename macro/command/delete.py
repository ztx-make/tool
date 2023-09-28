from .base import *


class DeleteMacroCommand(BlockMacroCommand):
    PARAM_DELETE_LINE = 'delete-line'

    def __init__(self, macro: Macro, command: str, matched: bool):
        super().__init__(macro, command, matched)
        self.options.add_option(StringsMacroCommandOption(DeleteMacroCommand.PARAM_DELETE_LINE, False))
        self.param_delete_lines: Optional[Set[str]] = None

    def apply_options(self):
        super().apply_options()
        self.param_delete_lines = self.options.get_value(DeleteMacroCommand.PARAM_DELETE_LINE)

    def _build_out(self, builder: MacroCommandOutBuilder):
        super()._build_out(builder)
        if self.matched:
            if self.param_delete_lines:
                lines = list(filter(lambda line: line.strip() not in self.param_delete_lines, self.lines))
                builder.append_result(matched=self.matched, delete_lines=len(self.lines) - len(lines))
                builder.append_lines(lines)
            else:
                builder.append_result(matched=self.matched, delete_lines=len(self.lines))
        else:
            builder.append_result(matched=self.matched)
            builder.append_lines(self.lines)
