import os

from .parser import *


class SrcReader:
    def __init__(self, macro_env: MacroEnv, src_config: SrcConfig):
        self.src_config = src_config
        self.src_parser = SrcParser(macro_env, self.src_config)
        self.file: Optional[IO] = None
        self.pending_element: [MacroCommand, str, None] = None
        self.pending_sections: List[MacroCommand, str] = []
        self.file_command: Optional[FileMacroCommand] = None

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def __iter__(self):
        return self

    def __next__(self):
        section = self.read_section()
        if section is None:
            raise StopIteration
        return section

    def open(self):
        # newline=None 可以将文件中的 \n，\r，\r\n 都识别为换行符，且读取后全部转换为 \n
        self.file = open(self.src_config.path, mode='r', encoding=self.src_config.encoding, newline=None)

        section = self._read_section()
        self.pending_sections.append(section)
        while not isinstance(section, FileMacroCommand):
            section = self._read_section()
            self.pending_sections.append(section)

        self.file_command = section

    def close(self):
        self.file.close()

    def read_section(self) -> Union[MacroParam, MacroCommand, str, None]:
        if len(self.pending_sections) == 0:
            return self._read_section()
        else:
            return self.pending_sections.pop(0)

    def _read_section(self) -> Union[MacroParam, MacroCommand, str, None]:
        element = self._read_element()
        if isinstance(element, MacroCommand):
            while True:
                next_element = self._read_element(element)
                if next_element is None:
                    break
                elif isinstance(next_element, MacroCommand):
                    self.pending_element = next_element
                    break
                elif isinstance(next_element, MacroParam):
                    element.options.set_param(next_element)
                elif isinstance(next_element, str):
                    if isinstance(element, BlockMacroCommand):
                        element.append_line(next_element)
                    else:
                        self.pending_element = next_element
                        break
            element.apply_options()
        return element

    def _read_element(
            self, current_command: Optional[MacroCommand] = None
    ) -> Union[MacroParam, MacroCommand, str, None]:
        if self.pending_element:
            pending_element = self.pending_element
            self.pending_element = None
            return pending_element

        line = self.file.readline()
        if line:
            return self.src_parser.parse_element(line, current_command)
        return None


class OutWriter:
    def __init__(self, out_config: OutConfig):
        self.out_config = out_config
        self.file: Optional[IO] = None

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def open(self):
        parent_dir = os.path.dirname(self.out_config.path)
        if not os.path.exists(parent_dir):
            os.makedirs(parent_dir)

        self.file = open(
            self.out_config.path, mode='w', encoding=self.out_config.encoding, newline=self.out_config.newline
        )

    def close(self):
        self.file.close()

    def _write_line(self, line: str):
        if line.endswith('\n'):
            self.file.write(line)
        else:
            self.file.write(line + '\n')

    def _write_lines(self, lines: List[str]):
        for line in lines:
            self._write_line(line)

    def write(self, section: [MacroCommand, str]):
        if isinstance(section, MacroCommand):
            self._write_lines(section.out(self.out_config))
        elif isinstance(section, str):
            self._write_line(section)
