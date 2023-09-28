from .base import *


class InsertMacroCommand(BlockMacroCommand):
    def _build_out(self, builder: MacroCommandOutBuilder):
        super()._build_out(builder)
        if self.matched:
            builder.append_result(matched=self.matched, insert_lines=len(self.lines))
            builder.append_lines(self.lines)
        else:
            builder.append_result(matched=self.matched, drop_lines=len(self.lines))
