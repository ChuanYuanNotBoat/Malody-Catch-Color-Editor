import json
import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import make_interp_spline
from tkinter import filedialog, Tk
from matplotlib.widgets import Button, Slider
import zipfile
import os
import threading
import pygame  # 用于音频播放
import time

# ----- 配置项 -----
NOTE_DENSITY = 16  # 每段生成多少个 note
DIVIDE = [1, 4]  # 当前分度，例如 [1,4] 表示 1/4 拍
X_TARGET_RANGE = 512
AUX_LINE_COUNT = 20  # 辅助线数量
ENABLE_SNAP = True  # 时间分度吸附是否开启（始终开启）

control_points = []  # 用户绘制的曲线点
curve_notes = []
curve_gen_enabled = True  # 曲线生成按钮状态
curve_shape_factor = 0.5  # 曲线形状控制滑条值，范围 [0, 1]

# 播放状态
is_playing = False
current_time = 0  # 当前播放时间（单位：毫秒）
bpm = 120  # 默认 BPM
audio_file = None  # 当前音频文件
# 全局变量初始化
current_notes = []  # 当前谱面的音符列表
loaded_surfaces = []  # 已加载的谱面集合

# y 轴缩放参数
y_min, y_max = 0, 10
y_range_size = 10  # 初始显示范围大小

# ----- 配置中文字体 -----
from matplotlib import rcParams
rcParams['font.sans-serif'] = ['SimHei']  # 设置中文字体为黑体
rcParams['axes.unicode_minus'] = False   # 显示负号

# ----- 工具函数 -----
def export_file(notes):
    """
    导出当前谱面到 .mc 文件
    """
    root = Tk()
    root.withdraw()
    file_path = filedialog.asksaveasfilename(defaultextension=".mc", filetypes=[("Malody Chart Files", "*.mc")])
    if not file_path:
        return

    data = {"note": notes}
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def load_new_surface():
    """
    加载新的谱面
    """
    global current_notes, background_image, audio_file, loaded_surfaces
    notes, bg_image, audio = import_file()
    if notes:
        loaded_surfaces.append((notes, bg_image, audio))
        switch_surface(len(loaded_surfaces) - 1)

def switch_surface(index):
    """
    切换到指定谱面
    """
    global current_notes, background_image, audio_file
    notes, bg_image, audio = loaded_surfaces[index]
    current_notes = notes
    background_image = bg_image
    audio_file = audio
    render()
def gcd(a, b):
    """
    计算最大公约数（用于简化分度）。
    :param a: 第一个整数。
    :param b: 第二个整数。
    :return: 最大公约数。
    """
    while b:
        a, b = b, a % b
    return a
def get_note_color_by_divide(beat):
    """
    根据时间分度获取音符颜色。
    :param beat: 音符的节拍信息，格式为 [小节数, 分子拍数, 分母拍数]。
    :return: 对应的颜色。
    """
    color_map = {
        (1, 1): 'red', (1, 2): 'blue', (1, 3): 'green',
        (1, 4): 'purple', (1, 6): 'green', (1, 8): 'yellow',
        (1, 12): 'green', (1, 16): 'yellow', (1, 24): 'green',
        (1, 32): 'yellow'
    }
    if beat[2] == 0:
        return 'gray'
    div = (1, beat[2] // gcd(beat[1], beat[2])) if beat[1] != 0 else (1, 1)
    return color_map.get(div, 'gray')
def normalize_x(notes):
    """
    归一化 note 的 x 坐标到指定范围 [0, X_TARGET_RANGE]。
    :param notes: 包含音符信息的列表，其中每个音符应包含 'x' 属性。
    :return: 坐标归一化后的音符列表。
    """
    xs = [n['x'] for n in notes if 'x' in n]
    if not xs:
        return notes
    min_x, max_x = min(xs), max(xs)
    scale = X_TARGET_RANGE / (max_x - min_x) if max_x != min_x else 1
    for n in notes:
        if 'x' in n:
            n['x'] = int((n['x'] - min_x) * scale)
    return notes
def generate_curve(points, density, shape_factor):
    """
    根据关键点生成平滑曲线的点列表。

    :param points: 关键点列表 [(x1, y1), (x2, y2), ...]
    :param density: 每段生成的点数量
    :param shape_factor: 曲线形状控制滑条值，范围 [0, 1]
    :return: 曲线点列表 [(x, y), ...]
    """
    if len(points) < 2:
        return []

    xs, ys = zip(*points)
    xs = np.array(xs)
    ys = np.array(ys)

    # 调整曲线形状，根据 shape_factor 修改插值点
    mid_xs = (xs[:-1] + xs[1:]) / 2
    mid_ys = (ys[:-1] + ys[1:]) / 2
    adjusted_xs = mid_xs + (xs[1:] - xs[:-1]) * (shape_factor - 0.5)

    # 插值点组合：起点 -> 调整点 -> 终点
    interp_xs = np.empty(len(xs) + len(adjusted_xs))
    interp_xs[0::2] = xs
    interp_xs[1::2] = adjusted_xs

    interp_ys = np.empty(len(ys) + len(mid_ys))
    interp_ys[0::2] = ys
    interp_ys[1::2] = mid_ys

    # 平滑曲线
    spline = make_interp_spline(interp_xs, interp_ys)
    xnew = np.linspace(min(xs), max(xs), density * (len(xs) - 1))
    ynew = spline(xnew)

    return list(zip(xnew, ynew))

def generate_and_place_notes(points, start_beat, density, shape_factor):
    """
    根据关键点生成曲线并放置音符。

    :param points: 关键点列表 [(x1, y1), (x2, y2), ...]
    :param start_beat: 起始拍数 [小节数, 分子拍数, 分母拍数]
    :param density: 每段生成的音符数量
    :param shape_factor: 曲线形状控制滑条值，范围 [0, 1]
    :return: 生成的音符列表
    """
    curve_points = generate_curve(points, density, shape_factor)
    if not curve_points:
        return []

    notes = []
    for i, (x, y) in enumerate(curve_points):
        beat_index = start_beat[0] * start_beat[2] + start_beat[1] + i * (start_beat[2] // (density * len(points)))
        beat = [beat_index // start_beat[2], beat_index % start_beat[2], start_beat[2]]
        notes.append({"beat": beat, "x": int(x)})

    return notes

def import_file():
    """
    导入 MCZ 文件，并加载 note 数据、背景图像和音频。
    """
    root = Tk()
    root.withdraw()
    file_path = filedialog.askopenfilename(filetypes=[("Malody Archive Files", "*.mcz")])
    if not file_path:
        return [], None, None

    if file_path.endswith('.mcz'):
        # 解压 MCZ 文件
        with zipfile.ZipFile(file_path, 'r') as z:
            temp_dir = file_path + "_temp"
            if not os.path.exists(temp_dir):
                os.makedirs(temp_dir)  # 创建临时目录
            z.extractall(temp_dir)

            # 查找 .mc 文件
            mc_files = [os.path.join(root, file) for root, _, files in os.walk(temp_dir) for file in files if file.endswith(".mc")]
            if not mc_files:
                raise FileNotFoundError(f"No MC file found in extracted MCZ directory: {temp_dir}")

            # 读取找到的第一个 .mc 文件
            mc_path = mc_files[0]
            with open(mc_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # 获取音符数据
            notes = data.get('note', [])
            notes = normalize_x(notes)

            # 查找背景图片
            image_files = [os.path.join(root, file) for root, _, files in os.walk(temp_dir) for file in files if file.endswith((".jpg", ".png"))]
            background_image = image_files[0] if image_files else None

            # 查找音频文件
            audio_files = [os.path.join(root, file) for root, _, files in os.walk(temp_dir) for file in files if file.endswith(".ogg")]
            audio_file = audio_files[0] if audio_files else None

            return notes, background_image, audio_file
    else:
        raise ValueError("The selected file is not a valid MCZ file.")

def play(render_function):
    """
    播放功能，根据 BPM 流速滚动时间范围，同时播放音频。
    """
    global is_playing, current_time, y_min, y_max, audio_file

    def update():
        global current_time, y_min, y_max
        start_time = time.time()  # 记录起始时间

        # 初始化音频播放
        if audio_file:
            pygame.mixer.init()
            pygame.mixer.music.load(audio_file)
            pygame.mixer.music.play(start=(current_time / 1000.0))  # 从当前时间点播放

        while is_playing:
            elapsed_time = (time.time() - start_time) * 1000  # 计算已过去的时间（毫秒）
            current_time += elapsed_time
            start_time = time.time()  # 重置起始时间

            # 更新显示范围
            beat_duration = 60000 / bpm  # 每拍时长（毫秒）
            y_min += elapsed_time / beat_duration
            y_max = y_min + y_range_size
            render_function()

            time.sleep(0.01)  # 减少 CPU 占用

        # 停止音频播放
        if audio_file:
            pygame.mixer.music.stop()

    thread = threading.Thread(target=update)
    thread.start()

def on_switch(event):
    """
    切换按钮触发函数，切换到下一个谱面
    """
    global current_notes, background_image, audio_file, loaded_surfaces
    if loaded_surfaces:
        current_index = loaded_surfaces.index((current_notes, background_image, audio_file))
        next_index = (current_index + 1) % len(loaded_surfaces)
        switch_surface(next_index)

def toggle_play(render_function):
    """
    切换播放/暂停状态。
    """
    global is_playing
    is_playing = not is_playing
    if is_playing:
        play(render_function)

def draw_editor(notes, background_image, audio_file_path):
    global y_min, y_max, y_range_size, AUX_LINE_COUNT, curve_notes, curve_gen_enabled, control_points, curve_shape_factor, audio_file
    audio_file = audio_file_path  # 记录音频文件路径

    fig, ax = plt.subplots()
    plt.subplots_adjust(bottom=0.35)  # 为按钮和两个滑条腾出空间

    # 初始化显示范围
    ax.set_xlim(0, X_TARGET_RANGE)
    ax.set_ylim(y_min, y_max)

    def filter_notes(notes, y_min, y_max):
        """仅渲染当前范围内的 note"""
        return [note for note in notes if 'beat' in note and y_min <= (note['beat'][0] + note['beat'][1] / note['beat'][2]) <= y_max]

    def render():
        """根据当前范围渲染图像"""
        ax.clear()

        # 恢复之前的显示范围
        ax.set_xlim(0, X_TARGET_RANGE)
        ax.set_ylim(y_min, y_max)

        # 绘制背景
        if background_image and os.path.exists(background_image):
            img = plt.imread(background_image)
            ax.imshow(img, extent=[0, X_TARGET_RANGE, y_min, y_max], aspect='auto', alpha=0.5)

        # 绘制时间分度辅助线
        for i in range(AUX_LINE_COUNT + 1):
            time_y = y_min + i * (y_max - y_min) / AUX_LINE_COUNT
            ax.axhline(time_y, color='gray', linestyle='--', alpha=0.3)

        # 绘制音符
        visible_notes = filter_notes(notes, y_min, y_max)
        for note in visible_notes:
            if 'endbeat' in note:
                start_y = note['beat'][0] + note['beat'][1] / note['beat'][2]
                end_y = note['endbeat'][0] + note['endbeat'][1] / note['beat'][2]
                ax.add_patch(plt.Rectangle((0, start_y), X_TARGET_RANGE, end_y - start_y, color='blue', alpha=0.3))
            elif 'x' in note:
                color = get_note_color_by_divide(note['beat'])
                time_y = note['beat'][0] + note['beat'][1] / note['beat'][2]
                ax.plot(note['x'], time_y, 'o', color=color, markersize=10)

        # 绘制用户控制点
        if control_points:
            x_cp, y_cp = zip(*control_points)
            ax.plot(x_cp, y_cp, 'ro-', label="控制点", markersize=10)

        # 绘制生成的曲线 note
        if curve_gen_enabled:
            for note in curve_notes:
                time_y = note['beat'][0] + note['beat'][1] / note['beat'][2]
                ax.plot(note['x'], time_y, 's', color='green', markersize=8)

        ax.set_title("Malody Catch 曲线编辑器")
        ax.set_xlabel("X [0-512]")
        ax.set_ylabel("时间 (拍数)")
        ax.grid(True)
        fig.canvas.draw_idle()

    # --- 鼠标事件 ---
    def on_press(event):
        if event.inaxes != ax:
            return
        if event.button == 1:  # 左键
            time_y = event.ydata
            snapped_beat = snap_beat([int(time_y), int((time_y % 1) * DIVIDE[1]), DIVIDE[1]], DIVIDE)
            control_points.append((event.xdata, snapped_beat[0] + snapped_beat[1] / snapped_beat[2]))
            render()
        elif event.button == 3 and control_points:  # 右键删除最近点
            control_points.pop()
            render()

    # --- 键盘事件 ---
    def on_key(event):
        global y_min, y_max, curve_notes
        if event.key == 'enter':  # 按回车放置音符
            if len(control_points) >= 2:
                curve_notes = generate_and_place_notes(control_points, [int(y_min), 0, DIVIDE[1]], NOTE_DENSITY, curve_shape_factor)
                notes.extend(curve_notes)
                control_points.clear()
                render()
        elif event.key == 'up':  # 向上平移
            y_min += 1
            y_max += 1
            render()
        elif event.key == 'down':  # 向下平移
            y_min = max(0, y_min - 1)
            y_max = max(y_range_size, y_max - 1)
            render()
        elif event.key == ' ':  # 播放/暂停
            toggle_play(render)

    # --- 滑条事件 ---
    def update_y_divide(val):
        """更新辅助线数量"""
        global AUX_LINE_COUNT
        AUX_LINE_COUNT = int(val)
        render()

    def update_curve_shape(val):
        """更新曲线形状控制滑条"""
        global curve_shape_factor
        curve_shape_factor = val
    def update_slider(val):
        global y_range_size, y_min, y_max
        y_range_size = slider_range.val
        y_max = y_min + y_range_size
        render()

    # --- 曲线开关按钮 ---
    def toggle_curve(event):
        global curve_gen_enabled
        curve_gen_enabled = not curve_gen_enabled
        render()

    # --- 控件区域 ---
    def on_import(event):
        """
        导入按钮触发函数，加载新的谱面
        """
        load_new_surface()

    def on_export(event):
        """
        导出按钮触发函数，保存当前谱面
        """
        export_file(current_notes)
# 导出谱面
def on_export(event):
    global current_notes
    export_file(current_notes)

    def on_switch(event):
        """
        切换按钮触发函数，切换到下一个谱面
        """
        if loaded_surfaces:
            current_index = loaded_surfaces.index((current_notes, background_image, audio_file))
            next_index = (current_index + 1) % len(loaded_surfaces)
            switch_surface(next_index)

    # 添加按钮控件
    ax_import = plt.axes([0.1, 0.02, 0.2, 0.05])
    btn_import = Button(ax_import, "导入谱面")
    btn_import.on_clicked(on_import)

def draw_editor(notes, background_image, audio_file_path):
    global y_min, y_max, y_range_size, AUX_LINE_COUNT, curve_notes, curve_gen_enabled, control_points, curve_shape_factor, audio_file
    audio_file = audio_file_path  # 记录音频文件路径

    fig, ax = plt.subplots()
    plt.subplots_adjust(bottom=0.4)  # 为按钮和滑条腾出更多空间
    # 添加按钮
    ax_import = plt.axes([0.1, 0.02, 0.2, 0.05])
    btn_import = Button(ax_import, "导入谱面")
    btn_import.on_clicked(load_new_surface)

    ax_export = plt.axes([0.4, 0.02, 0.2, 0.05])
    btn_export = Button(ax_export, "导出谱面")
    btn_export.on_clicked(on_export)
    ax_export = plt.axes([0.4, 0.02, 0.2, 0.05])
    btn_export = Button(ax_export, "导出谱面")
    btn_export.on_clicked(on_export)

    ax_switch = plt.axes([0.7, 0.02, 0.2, 0.05])
    btn_switch = Button(ax_switch, "切换谱面")
    btn_switch.on_clicked(on_switch)
    ax_button = plt.axes([0.7, 0.02, 0.25, 0.05])  # 曲线显示开关按钮
    btn = Button(ax_button, '切换曲线显示')
    btn.on_clicked(toggle_curve)

    ax_slider_y_divide = plt.axes([0.2, 0.1, 0.5, 0.03])  # 辅助线数量滑条
    slider_y_divide = Slider(ax_slider_y_divide, 'Y分度', 5, 50, valinit=AUX_LINE_COUNT, valstep=1)
    slider_y_divide.on_changed(update_y_divide)

    ax_slider_curve_shape = plt.axes([0.2, 0.05, 0.5, 0.03])  # 曲线形状控制滑条
    slider_curve_shape = Slider(ax_slider_curve_shape, '曲线形状', 0, 1, valinit=curve_shape_factor, valstep=0.01)
    slider_curve_shape.on_changed(update_curve_shape)

    ax_slider_range = plt.axes([0.2, 0.15, 0.5, 0.03])  # 滑条区域
    slider_range = Slider(ax_slider_range, 'Y范围大小', 1, 50, valinit=y_range_size)
    slider_range.on_changed(update_slider)

# --- 事件绑定 ---
fig.canvas.mpl_connect('button_press_event', on_press)
fig.canvas.mpl_connect('key_press_event', on_key)

render()  # 初次渲染
plt.show()

# ----- 主函数入口 -----
if __name__ == '__main__':
    notes, background_image, audio_file = import_file()
    draw_editor(notes, background_image, audio_file)
ax_switch = plt.axes([0.7, 0.02, 0.2, 0.05])
btn_switch = Button(ax_switch, "切换谱面")
btn_switch.on_clicked(lambda event: switch_surface((loaded_surfaces.index((current_notes, background_image, audio_file)) + 1) % len(loaded_surfaces)))