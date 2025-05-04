import json
import math
import os
import shutil
import sys


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
        # 创建备份
        backup_path = file_path + ".bak"
        shutil.copyfile(file_path, backup_path)

        # 读取并处理数据
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        for note in data.get('note', []):
            if 'beat' in note:
                note['beat'] = process_beat(note['beat'])

        # 覆盖写入原文件
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"成功处理: {os.path.basename(file_path)} (备份已保存为 {os.path.basename(backup_path)})")

    except Exception as e:
        print(f"处理失败: {os.path.basename(file_path)} | 错误: {str(e)}")


if __name__ == "__main__":
    # 获取脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # 切换到脚本目录
    os.chdir(script_dir)

    # 查找 .mc 文件
    mc_files = [f for f in os.listdir(script_dir) if f.endswith('.mc')]

    if not mc_files:
        print("错误: 未找到 .mc 文件！请确认：")
        print("1. 文件扩展名必须为 .mc（不是 .mc.txt 或其他）")
        print("2. 文件与脚本在同一目录下")
        print("3. 文件未被其他程序占用")
        sys.exit(1)

    print("=== 操作确认 ===")
    print("将处理以下文件:")
    for f in mc_files:
        print(f"  - {f}")
    confirm = input("输入 y 继续覆盖（生成 .bak 备份）: ")

    if confirm.lower() == 'y':
        for filename in mc_files:
            process_file(os.path.join(script_dir, filename))
        print("处理完成！")
    else:
        print("操作已取消。")
input("请按任意键继续")
