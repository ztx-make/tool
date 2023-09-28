from .io import *


class ProcessorConfig:
    def __init__(
            self,
            macro_env_variables: Dict[str, Union[str, int]],
            src_path: str, src_encoding: str, src_macro_sign: str, src_macro_param_prefix: str,
            out_path: str, out_encoding: str, out_newline: str, out_macro_keep: bool, out_macro_sign: str,
    ):
        self.macro_env_variables = macro_env_variables
        self.src_path = src_path
        self.src_encoding = src_encoding
        self.src_macro_sign = src_macro_sign
        self.src_macro_param_prefix = src_macro_param_prefix
        self.out_path = out_path
        self.out_encoding = out_encoding
        self.out_newline = out_newline
        self.out_macro_keep = out_macro_keep
        self.out_macro_sign = out_macro_sign

    def create_macro_env(self) -> MacroEnv:
        return MacroEnv(self.macro_env_variables)

    def create_src_config(self) -> SrcConfig:
        return SrcConfig(
            self.src_path, self.src_encoding, self.src_macro_sign, self.src_macro_param_prefix
        )

    def create_out_config(self, file_command: FileMacroCommand) -> OutConfig:
        out_config = OutConfig(
            self.out_path, self.out_encoding, self.out_newline, self.out_macro_keep, self.out_macro_sign
        )

        if file_command.param_out_macro_keep is not None:
            out_config.macro_keep = file_command.param_out_macro_keep
        if file_command.param_out_macro_sign is not None:
            out_config.macro_sign = file_command.param_out_macro_sign

        return out_config


class ProcessState(Enum):
    PROCESSED = 1,
    FAILED = 2,
    SKIPPED = 3,


class ProcessResult:
    def __init__(self, state: ProcessState, error: Optional[str] = None):
        self.state = state
        self.error = error


class Processor:
    def __init__(self, config: ProcessorConfig):
        self.config = config

    def process(self) -> ProcessResult:
        macro_env = self.config.create_macro_env()
        src_config = self.config.create_src_config()
        try:
            with SrcReader(macro_env, src_config) as reader:
                file_command = reader.file_command
                if file_command.matched:
                    out_config = self.config.create_out_config(file_command)
                    with OutWriter(out_config) as writer:
                        for section in reader:
                            writer.write(section)
                    return ProcessResult(ProcessState.PROCESSED)
                else:
                    return ProcessResult(ProcessState.SKIPPED)
        except MacroError as error:
            return ProcessResult(ProcessState.FAILED, str(error))
        except BaseException as error:
            return ProcessResult(ProcessState.FAILED, '%s: UnknownException -> %s' % (src_config.path, error))
