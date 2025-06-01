import json
import math
import os
import shutil
import sys
import tempfile
import zipfile
import locale

# 检测系统语言
system_language = locale.getlocale()[0] 
language = 'zh' if system_language and system_language.startswith('zh') else 'en'

# 定义翻译
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
    return translations[key][language].format(**kwargs)

def adjust_denominator(numerator, denominator):
    gcd_val = math.gcd(numerator, denominator)
    simplified_num = numerator // gcd_val
    simplified_den = denominator // gcd_val
    return simplified_num, simplified_den

def process_beat(beat):
    measure, num, den = beat
    adjusted_num, adjusted_den = adjust_denominator(num, den)
    return [measure, adjusted_num, adjusted_den]

def process_mc_file(mc_path, bak_dir):
    try:
        # 读取 .mc 文件数据
        with open(mc_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 处理所有音符节奏分数简化
        for note in data.get('note', []):
            if 'beat' in note:
                note['beat'] = process_beat(note['beat'])

        # 备份 .mc 文件，备份放在脚本目录（bak_dir）
        bak_path = os.path.join(bak_dir, os.path.basename(mc_path) + '.bak')
        shutil.copyfile(mc_path, bak_path)

        # 覆盖写入简化后的 .mc 文件
        with open(mc_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(translate('backup_created', file=os.path.basename(mc_path), backup=os.path.basename(bak_path)))

    except Exception as e:
        print(translate('process_failed', file=os.path.basename(mc_path), error=str(e)))

def process_mcz_file(mcz_path, output_dir):
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            # 解压.mcz
            with zipfile.ZipFile(mcz_path, 'r') as zip_ref:
                zip_ref.extractall(tmpdir)

            # 处理所有 .mc 文件
            mc_files = []
            for root, _, files in os.walk(tmpdir):
                for file in files:
                    if file.endswith('.mc'):
                        mc_files.append(os.path.join(root, file))

            if not mc_files:
                print(translate('no_mc_files'))
                return

            for mc_file in mc_files:
                process_mc_file(mc_file, output_dir)

            # 重新打包.mcz，排除所有.bak文件
            new_mcz_path = os.path.join(output_dir, os.path.basename(mcz_path))
            with zipfile.ZipFile(new_mcz_path, 'w', zipfile.ZIP_DEFLATED) as zip_write:
                for folder, _, files in os.walk(tmpdir):
                    for file in files:
                        if not file.endswith('.bak'):
                            file_path = os.path.join(folder, file)
                            arcname = os.path.relpath(file_path, tmpdir)
                            zip_write.write(file_path, arcname)

            print(f"重新打包完成：{os.path.basename(new_mcz_path)}")

    except Exception as e:
        print(f"处理MCZ文件失败: {e}")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    # 查找 .mc 和 .mcz 文件
    mc_files = [f for f in os.listdir(script_dir) if f.endswith('.mc')]
    mcz_files = [f for f in os.listdir(script_dir) if f.endswith('.mcz')]

    if not mc_files and not mcz_files:
        print(translate('no_mc_files'))
        sys.exit(1)

    print(translate('operation_confirm'))
    for f in mc_files + mcz_files:
        print(f"  - {f}")
    confirm = input(translate('input_confirm'))

    if confirm.lower() == 'y':
        for mc_file in mc_files:
            process_mc_file(os.path.join(script_dir, mc_file), script_dir)
        for mcz_file in mcz_files:
            process_mcz_file(os.path.join(script_dir, mcz_file), script_dir)
        print(translate('processing_complete'))
    else:
        print(translate('operation_cancelled'))

    input(translate('press_any_key'))

if __name__ == "__main__":
    main()
