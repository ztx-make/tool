#!/usr/bin/python3
import os
import sys
from configparser import ConfigParser
from typing import *

from processor import ProcessorConfig, ProcessState, ProcessResult, Processor

FEATURE_PREFIX_KEY = 'SCL_FEATURE_KEY_PREFIX'
FEATURE_PREFIX_DEFAULT = 'ZTX_MACRO_'
GLOBAL_CONFIG_FILE_NAME = 'ztx_macro.ini'

SRC_ENCODING_DEFAULT = "UTF-8"
SRC_MACRO_SIGN_DEFAULT = "@ztx-macro"
SRC_MACRO_PARAM_PREFIX_DEFAULT = "param "

OUT_ENCODING_DEFAULT = "UTF-8"
OUT_NEWLINE_DEFAULT = 'LF'
OUT_MACRO_KEEP = True
OUT_MACRO_SIGN = '#ztx-macro'


def parse_newline_type(newline_type: str) -> str:
    newline_type = newline_type.upper()
    if newline_type == 'CRLF':
        return '\r\n'
    elif newline_type == 'CR':
        return '\r'
    else:
        return '\n'


def load_src_files(root_dir: str, short_path: str = '') -> List[str]:
    full_path = os.path.join(root_dir, short_path)
    if os.path.isfile(full_path):
        return [short_path]
    elif os.path.isdir(full_path):
        result: List[str] = []
        subs = os.listdir(full_path)
        for sub in subs:
            sub_short_path = os.path.join(short_path, sub)
            result.extend(load_src_files(root_dir, sub_short_path))
        return result
    return []


def load_macro_env_variables() -> Dict[str, Union[str, int]]:
    envs: Dict[str, Union[str, int]] = {}
    feature_prefix = os.environ[FEATURE_PREFIX_KEY] if FEATURE_PREFIX_KEY in os.environ else FEATURE_PREFIX_DEFAULT
    for key in os.environ:
        if key.startswith(feature_prefix):
            value = os.environ[key]
            feature_key = key[len(feature_prefix):]
            if value.isdigit():
                envs[feature_key] = int(value)
            else:
                envs[feature_key] = value
    return envs


def load_global_configs(config_file: str) -> ConfigParser:
    configs = ConfigParser()
    if os.path.exists(config_file):
        configs.read(config_file, encoding='UTF-8')
    return configs


def load_processor_config(
        global_configs: ConfigParser,
        macro_env_variables: Dict[str, Union[str, int]],
        src_dir: str, out_dir: str, file: str,
) -> ProcessorConfig:
    src_encoding = global_configs.get(file, 'src-encoding', fallback=SRC_ENCODING_DEFAULT)
    src_macro_sign = global_configs.get(file, 'src-macro-sign', fallback=SRC_MACRO_SIGN_DEFAULT)
    src_macro_param_prefix = global_configs.get(file, 'src-macro-param-prefix', fallback=SRC_MACRO_PARAM_PREFIX_DEFAULT)

    out_encoding = global_configs.get(file, 'out-encoding', fallback=OUT_ENCODING_DEFAULT)
    out_newline = parse_newline_type(global_configs.get(file, 'out-newline', fallback=OUT_NEWLINE_DEFAULT))
    out_macro_keep = global_configs.getboolean(file, 'out-macro-keep', fallback=OUT_MACRO_KEEP)
    out_macro_sign = global_configs.get(file, 'out-macro-sign', fallback=OUT_MACRO_SIGN)

    return ProcessorConfig(
        macro_env_variables,
        os.path.join(src_dir, file),
        src_encoding,
        src_macro_sign,
        src_macro_param_prefix,
        os.path.join(out_dir, file),
        out_encoding,
        out_newline,
        out_macro_keep,
        out_macro_sign,
    )


def process(processor_config: ProcessorConfig) -> ProcessResult:
    return Processor(processor_config).process()


def main():
    if len(sys.argv) != 3:
        print('args error: %s' % sys.argv[1:])
        exit(1)

    src_dir = os.path.abspath(sys.argv[1])
    out_dir = os.path.abspath(sys.argv[2])

    print("src dir: %s" % src_dir)
    print("out dir: %s" % out_dir)

    if not os.path.exists(src_dir):
        print('[%s] not found' % src_dir)
        exit(1)

    if not os.path.isdir(src_dir):
        print('[%s] not dir' % src_dir)
        exit(1)

    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    if not os.path.isdir(out_dir):
        print('[%s] not dir' % out_dir)
        exit(1)

    files = load_src_files(src_dir)
    macro_env_variables = load_macro_env_variables()
    global_configs = load_global_configs(os.path.join(src_dir, GLOBAL_CONFIG_FILE_NAME))
    for file in files:
        if file == GLOBAL_CONFIG_FILE_NAME:
            continue
        processor_config = load_processor_config(global_configs, macro_env_variables, src_dir, out_dir, file)
        result = process(processor_config)
        if result.state == ProcessState.FAILED:
            print(result.error)
            exit(1)
        elif result.state == ProcessState.PROCESSED:
            print('processed: %s' % file)
        else:
            print('skipped: %s' % file)


if __name__ == '__main__':
    main()
