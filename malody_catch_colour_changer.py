import json
import math
import os
import shutil
import sys
import locale

def detect_language():
    try:
        lang_tuple = locale.getlocale()
        lang_code = lang_tuple[0] if lang_tuple and lang_tuple[0] else 'en_US'
    except Exception:
        lang_code = 'en_US'
    # 只要包含 "zh" 或 "chinese" 都判定为中文，其余一律英文
    if lang_code and ('zh' in lang_code.lower() or 'chinese' in lang_code.lower()):
        return 'zh'
    else:
        return 'en'

language = detect_language()

translations = {
    'backup_created': {
        'zh': "成功处理: {file} (备份已保存为 {backup})",
        'en': "Successfully processed: {file} (Backup saved as {backup})"
    },
    'process_failed': {
        'zh': "处理失败: {file} | 错误: {error}",
        'en': "Processing failed: {file} | Error: {error}"
    },
    'no_mc_files': {
        'zh': "错误: 未找到 .mc 文件！请确认：\n1. 文件扩展名必须为 .mc \n2. 文件与脚本在同一目录下\n3. 文件未被其他程序占用",
        'en': "Error: No .mc files found! Please ensure:\n1. File extension must be .mc \n2. Files are in the same directory as the script\n3. Files are not occupied by other programs"
    },
    'operation_confirm': {
        'zh': "=== 操作确认 ===\n将处理以下文件:",
        'en': "=== Operation Confirmation ===\nThe following files will be processed:"
    },
    'input_confirm': {
        'zh': "输入 y 继续覆盖（生成 .bak 备份）: ",
        'en': "Enter y to continue overwriting (a .bak backup will be created): "
    },
    'operation_cancelled': {
        'zh': "操作已取消。",
        'en': "Operation cancelled."
    },
    'processing_complete': {
        'zh': "处理完成！",
        'en': "Processing complete!"
    },
    'press_any_key': {
        'zh': "请按任意键继续",
        'en': "Press any key to continue"
    }
}

def translate(key, **kwargs):
    if key not in translations:
        return key
    lang_map = translations[key]
    if language == 'zh' and 'zh' in lang_map:
        return lang_map['zh'].format(**kwargs)
    else:
        return lang_map.get('en', key).format(**kwargs)

def adjust_denominator(numerator, denominator):
    gcd_val = math.gcd(numerator, denominator)
    simplified_num = numerator // gcd_val
    simplified_den = denominator // gcd_val
    return (simplified_num * 2, 2) if simplified_den < 2 else (simplified_num, simplified_den)

def process_beat(beat):
    measure, num, den = beat
    adjusted_num, adjusted_den = adjust_denominator(num, den)
    return [measure, adjusted_num, adjusted_den]

def process_file(file_path):
    try:
        backup_path = file_path + ".bak"
        shutil.copyfile(file_path, backup_path)
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        for note in data.get('note', []):
            if 'beat' in note:
                note['beat'] = process_beat(note['beat'])
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(translate('backup_created', file=os.path.basename(file_path), backup=os.path.basename(backup_path)))
    except Exception as e:
        print(translate('process_failed', file=os.path.basename(file_path), error=str(e)))

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    mc_files = [f for f in os.listdir(script_dir) if f.endswith('.mc')]
    if not mc_files:
        print(translate('no_mc_files'))
        sys.exit(1)
    print(translate('operation_confirm'))
    for f in mc_files:
        print(f"  - {f}")
    confirm = input(translate('input_confirm'))
    if confirm.lower() == 'y':
        for filename in mc_files:
            process_file(os.path.join(script_dir, filename))
        print(translate('processing_complete'))
    else:
        print(translate('operation_cancelled'))
    input(translate('press_any_key'))