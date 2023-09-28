from base import *
from .base import MacroCommand
from .delete import DeleteMacroCommand
from .end import EndMacroCommand
from .fallback import FallbackMacroCommand
from .file import FileMacroCommand
from .insert import InsertMacroCommand
from .template import TemplateMacroCommand


class MacroCommandFactory:
    COMMAND_BUILDERS: Dict[str, Callable[[Macro, str, bool], MacroCommand]] = {
        'file': lambda macro, command, matched: FileMacroCommand(macro, command, matched),
        'insert': lambda macro, command, matched: InsertMacroCommand(macro, command, matched),
        'delete': lambda macro, command, matched: DeleteMacroCommand(macro, command, matched),
        'template': lambda macro, command, matched: TemplateMacroCommand(macro, command, matched),
        'fallback': lambda macro, command, matched: FallbackMacroCommand(macro, command, matched),
        'end': lambda macro, command, matched: EndMacroCommand(macro, command, matched),
    }

    @staticmethod
    def create(macro: Macro, command: str, matched: bool):
        if command in MacroCommandFactory.COMMAND_BUILDERS:
            return MacroCommandFactory.COMMAND_BUILDERS[command](macro, command, matched)
        macro.src_position.raise_syntax_error('FACTORY_1', '未知的宏指令', command=command)

    @staticmethod
    def is_fallback(command: str):
        return command == 'fallback'

    @staticmethod
    def is_end(command: str):
        return command == 'end'
