#!/usr/bin/env python3
"""
あやとりパズルゲーム用 効果音・ジングル生成スクリプト

numpy と scipy のみを使用して、ゲームに必要な全音声ファイルを生成します。
温かみのある、かわいい日本的な雰囲気に合ったサウンドを目指しています。

使い方: python generate_sounds.py
"""

import numpy as np
from scipy.io import wavfile
import os

# === 基本設定 ===
SAMPLE_RATE = 44100
BIT_DEPTH = 16  # 16ビット


def normalize(audio, peak=0.9):
    """オーディオ信号を正規化してクリッピングを防ぐ"""
    max_val = np.max(np.abs(audio))
    if max_val > 0:
        audio = audio * (peak / max_val)
    return audio


def apply_envelope(audio, attack_ms, decay_ms, sustain_level, release_ms):
    """ADSR エンベロープを適用して自然なサウンドを実現する"""
    n = len(audio)
    attack_samples = int(SAMPLE_RATE * attack_ms / 1000)
    decay_samples = int(SAMPLE_RATE * decay_ms / 1000)
    release_samples = int(SAMPLE_RATE * release_ms / 1000)
    sustain_samples = max(0, n - attack_samples - decay_samples - release_samples)

    envelope = np.zeros(n)
    pos = 0

    # アタック部分（立ち上がり）
    if attack_samples > 0:
        end = min(pos + attack_samples, n)
        envelope[pos:end] = np.linspace(0, 1, end - pos)
        pos = end

    # ディケイ部分（減衰）
    if decay_samples > 0 and pos < n:
        end = min(pos + decay_samples, n)
        envelope[pos:end] = np.linspace(1, sustain_level, end - pos)
        pos = end

    # サスティン部分（持続）
    if sustain_samples > 0 and pos < n:
        end = min(pos + sustain_samples, n)
        envelope[pos:end] = sustain_level
        pos = end

    # リリース部分（消音）
    if release_samples > 0 and pos < n:
        end = min(pos + release_samples, n)
        envelope[pos:end] = np.linspace(sustain_level, 0, end - pos)
        pos = end

    return audio * envelope


def add_reverb(audio, decay=0.3, delay_ms=30, iterations=5):
    """簡易リバーブ（指数減衰によるディレイの畳み込み）"""
    delay_samples = int(SAMPLE_RATE * delay_ms / 1000)
    result = audio.copy()
    for i in range(1, iterations + 1):
        offset = delay_samples * i
        gain = decay ** i
        if offset < len(result):
            delayed = np.zeros(len(result))
            delayed[offset:] = audio[:len(audio) - offset] * gain
            result += delayed
    return result


def sine_wave(freq, duration_ms, phase=0):
    """正弦波を生成する"""
    t = np.linspace(0, duration_ms / 1000, int(SAMPLE_RATE * duration_ms / 1000), endpoint=False)
    return np.sin(2 * np.pi * freq * t + phase)


def exponential_decay(duration_ms, decay_rate=5.0):
    """指数減衰カーブを生成する"""
    t = np.linspace(0, duration_ms / 1000, int(SAMPLE_RATE * duration_ms / 1000), endpoint=False)
    return np.exp(-decay_rate * t)


def white_noise(duration_ms, amplitude=1.0):
    """ホワイトノイズを生成する"""
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    return np.random.randn(n_samples) * amplitude


def save_wav(filename, audio):
    """WAVファイルとして保存する（16ビット）"""
    # 正規化
    audio = normalize(audio, peak=0.9)
    # 16ビット整数に変換
    audio_int16 = np.int16(audio * 32767)
    wavfile.write(filename, SAMPLE_RATE, audio_int16)


def freq_from_note(note_name):
    """音名から周波数を返す（A4=440Hz基準）"""
    notes = {
        'C3': 130.81, 'D3': 146.83, 'E3': 164.81, 'F3': 174.61,
        'G3': 196.00, 'A3': 220.00, 'B3': 246.94,
        'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23,
        'G4': 392.00, 'A4': 440.00, 'B4': 493.88,
        'C5': 523.25, 'D5': 587.33, 'E5': 659.26, 'F5': 698.46,
        'G5': 783.99, 'A5': 880.00, 'B5': 987.77,
        'C6': 1046.50, 'D6': 1174.66, 'E6': 1318.51,
    }
    return notes.get(note_name, 440.0)


# === SE 生成関数 ===

def generate_button_tap():
    """ボタンタップ音 - 柔らかい木琴のようなタップ音"""
    duration_ms = 100

    # 基音（温かみのある中音域）
    fundamental = sine_wave(880, duration_ms) * 0.6
    # 第2倍音（木琴らしさ）
    harmonic2 = sine_wave(880 * 2.76, duration_ms) * 0.3
    # 第3倍音（明るさを追加）
    harmonic3 = sine_wave(880 * 5.4, duration_ms) * 0.1

    sound = fundamental + harmonic2 + harmonic3

    # 速い減衰で短いタップ感
    decay = exponential_decay(duration_ms, decay_rate=25.0)
    sound *= decay

    # 軽いアタック
    attack_samples = int(SAMPLE_RATE * 2 / 1000)  # 2ms
    if attack_samples > 0 and attack_samples < len(sound):
        sound[:attack_samples] *= np.linspace(0, 1, attack_samples)

    # 軽いリバーブで空間感
    sound = add_reverb(sound, decay=0.15, delay_ms=10, iterations=3)

    return sound


def generate_string_hook():
    """弦をかける音 - ハープのような弦の撥音"""
    duration_ms = 300

    # ハープ風の豊かな倍音構成
    fundamental = sine_wave(freq_from_note('E5'), duration_ms) * 0.5
    harmonic2 = sine_wave(freq_from_note('E5') * 2, duration_ms) * 0.25
    harmonic3 = sine_wave(freq_from_note('E5') * 3, duration_ms) * 0.12
    harmonic4 = sine_wave(freq_from_note('E5') * 4, duration_ms) * 0.06
    harmonic5 = sine_wave(freq_from_note('E5') * 5, duration_ms) * 0.03

    sound = fundamental + harmonic2 + harmonic3 + harmonic4 + harmonic5

    # プラック（撥弦）のエンベロープ - 素早いアタック、なめらかな減衰
    sound = apply_envelope(sound, attack_ms=3, decay_ms=80, sustain_level=0.3, release_ms=150)

    # 弦の振動を模したわずかなビブラート
    t = np.linspace(0, duration_ms / 1000, len(sound), endpoint=False)
    vibrato = 1.0 + 0.003 * np.sin(2 * np.pi * 6 * t) * exponential_decay(duration_ms, 3.0)
    sound *= vibrato

    # 軽いリバーブ
    sound = add_reverb(sound, decay=0.2, delay_ms=20, iterations=4)

    return sound


def generate_string_unhook():
    """弦を外す音 - 柔らかい弦のリリース音"""
    duration_ms = 200

    # hookより低めの音で柔らかさを演出
    fundamental = sine_wave(freq_from_note('C5'), duration_ms) * 0.4
    harmonic2 = sine_wave(freq_from_note('C5') * 2, duration_ms) * 0.15
    harmonic3 = sine_wave(freq_from_note('C5') * 3, duration_ms) * 0.08

    sound = fundamental + harmonic2 + harmonic3

    # 逆エンベロープ風 - フェードインしてから消える
    n = len(sound)
    fade_in_samples = int(n * 0.15)
    sustain_samples = int(n * 0.25)
    fade_out_samples = n - fade_in_samples - sustain_samples

    envelope = np.zeros(n)
    envelope[:fade_in_samples] = np.linspace(0, 0.7, fade_in_samples)
    envelope[fade_in_samples:fade_in_samples + sustain_samples] = np.linspace(0.7, 0.5, sustain_samples)
    envelope[fade_in_samples + sustain_samples:] = np.linspace(0.5, 0, fade_out_samples)

    sound *= envelope

    # ピッチの微妙な下降（弦が緩む感じ）
    t = np.linspace(0, duration_ms / 1000, n, endpoint=False)
    pitch_bend = np.exp(-1.5 * t)
    # ピッチベンドを位相に適用
    base_freq = freq_from_note('C5')
    phase_mod = sine_wave(base_freq * 0.02, duration_ms) * pitch_bend * 0.3
    sound += phase_mod * envelope * 0.1

    # リバーブ
    sound = add_reverb(sound, decay=0.25, delay_ms=25, iterations=4)

    return sound


def generate_undo():
    """元に戻す音 - 素早い逆再生スウィープ"""
    duration_ms = 150
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    t = np.linspace(0, duration_ms / 1000, n_samples, endpoint=False)

    # 下降する周波数スウィープ（1200Hz → 400Hz）
    freq_start = 1200
    freq_end = 400
    freq = np.linspace(freq_start, freq_end, n_samples)
    phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
    sound = np.sin(phase) * 0.5

    # 倍音を追加して豊かさを出す
    freq2 = freq * 2
    phase2 = 2 * np.pi * np.cumsum(freq2) / SAMPLE_RATE
    sound += np.sin(phase2) * 0.15

    # エンベロープ
    sound = apply_envelope(sound, attack_ms=5, decay_ms=30, sustain_level=0.5, release_ms=60)

    # 軽いリバーブ
    sound = add_reverb(sound, decay=0.15, delay_ms=15, iterations=3)

    return sound


def generate_reset():
    """リセット音 - シマー/チャイム音"""
    duration_ms = 400
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    t = np.linspace(0, duration_ms / 1000, n_samples, endpoint=False)

    # 複数の高音域の倍音を重ねてシマー感を出す
    freqs = [
        freq_from_note('C6'),
        freq_from_note('E6'),
        freq_from_note('G5'),
        freq_from_note('C5'),
    ]
    amps = [0.3, 0.25, 0.2, 0.15]
    decay_rates = [4.0, 5.0, 3.5, 3.0]

    sound = np.zeros(n_samples)
    for freq, amp, dr in zip(freqs, amps, decay_rates):
        wave = sine_wave(freq, duration_ms) * amp
        # 各音にわずかな時間差
        wave *= exponential_decay(duration_ms, dr)
        # 高次倍音の追加（きらめき）
        wave += sine_wave(freq * 3, duration_ms) * amp * 0.1 * exponential_decay(duration_ms, dr * 1.5)
        sound += wave

    # 微細なノイズでシマー感を演出
    noise = white_noise(duration_ms, 0.02) * exponential_decay(duration_ms, 8.0)
    sound += noise

    # エンベロープ
    sound = apply_envelope(sound, attack_ms=5, decay_ms=50, sustain_level=0.4, release_ms=200)

    # リバーブで広がり感
    sound = add_reverb(sound, decay=0.3, delay_ms=25, iterations=5)

    return sound


def generate_panel_open():
    """パネルを開く音 - 上昇するウーッシュ"""
    duration_ms = 200
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    t = np.linspace(0, duration_ms / 1000, n_samples, endpoint=False)

    # 上昇する周波数スウィープ
    freq_start = 300
    freq_end = 900
    freq = np.linspace(freq_start, freq_end, n_samples)
    phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
    tone = np.sin(phase) * 0.3

    # フィルタリングしたホワイトノイズでウーッシュ感
    noise = white_noise(duration_ms, 0.15)
    # 簡易ローパス（移動平均）
    kernel_size = 15
    kernel = np.ones(kernel_size) / kernel_size
    noise = np.convolve(noise, kernel, mode='same')

    # ノイズにも上昇感を持たせる
    noise_envelope = np.linspace(0.3, 1.0, n_samples) * exponential_decay(duration_ms, 3.0)
    noise *= noise_envelope

    sound = tone + noise

    # エンベロープ - 素早い立ち上がりと自然な消え方
    sound = apply_envelope(sound, attack_ms=10, decay_ms=60, sustain_level=0.5, release_ms=80)

    # 軽いリバーブ
    sound = add_reverb(sound, decay=0.15, delay_ms=15, iterations=3)

    return sound


def generate_panel_close():
    """パネルを閉じる音 - 下降するウーッシュ"""
    duration_ms = 150
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    t = np.linspace(0, duration_ms / 1000, n_samples, endpoint=False)

    # 下降する周波数スウィープ
    freq_start = 800
    freq_end = 250
    freq = np.linspace(freq_start, freq_end, n_samples)
    phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
    tone = np.sin(phase) * 0.3

    # フィルタリングしたノイズ
    noise = white_noise(duration_ms, 0.12)
    kernel_size = 15
    kernel = np.ones(kernel_size) / kernel_size
    noise = np.convolve(noise, kernel, mode='same')

    # ノイズに下降感
    noise_envelope = np.linspace(1.0, 0.2, n_samples) * exponential_decay(duration_ms, 4.0)
    noise *= noise_envelope

    sound = tone + noise

    # エンベロープ
    sound = apply_envelope(sound, attack_ms=5, decay_ms=40, sustain_level=0.4, release_ms=60)

    # リバーブ
    sound = add_reverb(sound, decay=0.12, delay_ms=12, iterations=3)

    return sound


def generate_star_get():
    """星を獲得した音 - スパークル/グロッケンシュピール音"""
    duration_ms = 300
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    t = np.linspace(0, duration_ms / 1000, n_samples, endpoint=False)

    # グロッケンシュピール風のベル音（C5とE5の和音）
    bell_c = sine_wave(freq_from_note('C6'), duration_ms) * 0.3
    bell_e = sine_wave(freq_from_note('E6'), duration_ms) * 0.25

    # ベル特有の非整数倍音
    bell_c += sine_wave(freq_from_note('C6') * 2.76, duration_ms) * 0.1
    bell_e += sine_wave(freq_from_note('E6') * 2.76, duration_ms) * 0.08

    # 明るいキラキラ倍音
    sparkle = sine_wave(freq_from_note('G5') * 4, duration_ms) * 0.05
    sparkle += sine_wave(freq_from_note('C6') * 5, duration_ms) * 0.03

    sound = bell_c + bell_e + sparkle

    # ベル音のエンベロープ（素早いアタック、長めの減衰）
    sound = apply_envelope(sound, attack_ms=2, decay_ms=60, sustain_level=0.3, release_ms=180)

    # きらめきエフェクト（高周波の小さなパルス）
    sparkle_times = [0.05, 0.12, 0.2]
    for st in sparkle_times:
        idx = int(st * SAMPLE_RATE)
        spark_len = int(0.03 * SAMPLE_RATE)
        if idx + spark_len < n_samples:
            spark = np.sin(2 * np.pi * 3500 * np.linspace(0, 0.03, spark_len)) * 0.04
            spark *= exponential_decay(30, 40.0)
            sound[idx:idx + spark_len] += spark

    # リバーブでベルの響き
    sound = add_reverb(sound, decay=0.3, delay_ms=30, iterations=5)

    return sound


def generate_transition():
    """画面遷移音 - 柔らかいパッドスウィープ"""
    duration_ms = 500
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    t = np.linspace(0, duration_ms / 1000, n_samples, endpoint=False)

    # 温かみのあるパッドサウンド（Cメジャー和音）
    pad_c = sine_wave(freq_from_note('C4'), duration_ms) * 0.25
    pad_e = sine_wave(freq_from_note('E4'), duration_ms) * 0.2
    pad_g = sine_wave(freq_from_note('G4'), duration_ms) * 0.2

    # 各音に少しデチューンしたコピーを重ねて厚みを出す
    pad_c += sine_wave(freq_from_note('C4') * 1.003, duration_ms) * 0.15
    pad_e += sine_wave(freq_from_note('E4') * 0.998, duration_ms) * 0.12
    pad_g += sine_wave(freq_from_note('G4') * 1.002, duration_ms) * 0.12

    sound = pad_c + pad_e + pad_g

    # ゆるやかな上昇感（ピッチの微妙な上昇）
    pitch_rise = np.linspace(1.0, 1.02, n_samples)
    sound_shifted = np.zeros(n_samples)
    base_freq = freq_from_note('C5')
    for i, pr in enumerate(pitch_rise):
        sound_shifted[i] = sound[i] * pr

    sound = sound_shifted

    # 柔らかいエンベロープ
    sound = apply_envelope(sound, attack_ms=80, decay_ms=100, sustain_level=0.6, release_ms=200)

    # リバーブで空間感
    sound = add_reverb(sound, decay=0.35, delay_ms=35, iterations=6)

    return sound


# === ジングル生成関数 ===

def generate_note(freq, duration_ms, wave_type='sine', harmonics=True):
    """1音を生成するヘルパー関数"""
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    t = np.linspace(0, duration_ms / 1000, n_samples, endpoint=False)

    sound = np.sin(2 * np.pi * freq * t) * 0.5

    if harmonics:
        # 温かみのある倍音
        sound += np.sin(2 * np.pi * freq * 2 * t) * 0.15
        sound += np.sin(2 * np.pi * freq * 3 * t) * 0.08
        sound += np.sin(2 * np.pi * freq * 4 * t) * 0.04

    return sound


def generate_level_clear():
    """レベルクリア ジングル - 短い祝福のファンファーレ"""
    # C-E-G の分散和音、その後 高いC-E-G-C
    # テンポ感: 軽快で達成感がある

    parts = []

    # パート1: C-E-G 上昇分散和音（各音120ms）
    note_dur = 120
    notes_1 = ['C5', 'E5', 'G5']
    for note in notes_1:
        freq = freq_from_note(note)
        n = generate_note(freq, note_dur)
        n = apply_envelope(n, attack_ms=3, decay_ms=30, sustain_level=0.6, release_ms=40)
        parts.append(n)

    # 短い間
    gap = np.zeros(int(SAMPLE_RATE * 0.05))
    parts.append(gap)

    # パート2: 高いC-E-G-C の和音（長め、600ms）
    chord_dur = 800
    chord = np.zeros(int(SAMPLE_RATE * chord_dur / 1000))
    chord_notes = ['C5', 'E5', 'G5', 'C6']
    chord_amps = [0.35, 0.3, 0.25, 0.3]

    for note, amp in zip(chord_notes, chord_amps):
        freq = freq_from_note(note)
        n = generate_note(freq, chord_dur)
        # デチューン版でコーラス効果
        n += generate_note(freq * 1.002, chord_dur) * 0.4
        n *= amp
        chord += n[:len(chord)]

    chord = apply_envelope(chord, attack_ms=10, decay_ms=100, sustain_level=0.5, release_ms=400)
    parts.append(chord)

    # 結合
    sound = np.concatenate(parts)

    # 全体にリバーブ
    sound = add_reverb(sound, decay=0.3, delay_ms=40, iterations=5)

    return sound


def generate_perfect_clear():
    """パーフェクトクリア ジングル - より豪華なファンファーレ"""
    parts = []

    # パート1: C-E-G 速い上昇アルペジオ（各音90ms）
    note_dur = 90
    notes_1 = ['C5', 'E5', 'G5']
    for note in notes_1:
        freq = freq_from_note(note)
        n = generate_note(freq, note_dur)
        n = apply_envelope(n, attack_ms=2, decay_ms=20, sustain_level=0.6, release_ms=30)
        parts.append(n)

    # 短い間
    gap1 = np.zeros(int(SAMPLE_RATE * 0.03))
    parts.append(gap1)

    # パート2: 高いC-E-G アルペジオ（各音100ms）
    notes_2 = ['C5', 'E5', 'G5', 'B5']
    for note in notes_2:
        freq = freq_from_note(note)
        n = generate_note(freq, 100)
        n = apply_envelope(n, attack_ms=2, decay_ms=25, sustain_level=0.6, release_ms=35)
        parts.append(n)

    # 短い間
    gap2 = np.zeros(int(SAMPLE_RATE * 0.04))
    parts.append(gap2)

    # パート3: 豪華な最終和音（C-E-G-B-C6）（1000ms）
    chord_dur = 1000
    chord = np.zeros(int(SAMPLE_RATE * chord_dur / 1000))
    chord_notes = ['C4', 'C5', 'E5', 'G5', 'B5', 'C6', 'E6']
    chord_amps = [0.2, 0.3, 0.25, 0.22, 0.18, 0.28, 0.15]

    for note, amp in zip(chord_notes, chord_amps):
        freq = freq_from_note(note)
        n = generate_note(freq, chord_dur, harmonics=True)
        # コーラス効果
        n += generate_note(freq * 1.003, chord_dur) * 0.3
        n += generate_note(freq * 0.997, chord_dur) * 0.3
        n *= amp
        chord += n[:len(chord)]

    chord = apply_envelope(chord, attack_ms=15, decay_ms=150, sustain_level=0.5, release_ms=500)

    # きらめきオーバートーン（パーフェクトらしい特別感）
    sparkle_dur = chord_dur
    n_sparkle = int(SAMPLE_RATE * sparkle_dur / 1000)
    t_sparkle = np.linspace(0, sparkle_dur / 1000, n_sparkle, endpoint=False)

    # ランダムなタイミングでキラキラ
    np.random.seed(42)  # 再現性のためシードを固定
    num_sparkles = 8
    for _ in range(num_sparkles):
        spark_start = np.random.uniform(0.05, 0.7)
        spark_freq = np.random.uniform(2000, 4000)
        spark_dur_s = 0.04
        spark_samples = int(spark_dur_s * SAMPLE_RATE)
        start_idx = int(spark_start * SAMPLE_RATE)

        if start_idx + spark_samples < len(chord):
            spark_t = np.linspace(0, spark_dur_s, spark_samples, endpoint=False)
            spark = np.sin(2 * np.pi * spark_freq * spark_t) * 0.03
            spark *= np.exp(-30 * spark_t)
            chord[start_idx:start_idx + spark_samples] += spark

    parts.append(chord)

    # 結合
    sound = np.concatenate(parts)

    # リバーブ（より豪華に）
    sound = add_reverb(sound, decay=0.35, delay_ms=45, iterations=6)

    return sound


# === メイン処理 ===

def main():
    # Windows コンソールでの文字化けを防止
    import sys
    sys.stdout.reconfigure(encoding='utf-8')

    print("=" * 50)
    print("[*] あやとりパズルゲーム サウンド生成スクリプト")
    print("=" * 50)
    print()

    # ディレクトリの作成
    dirs = [
        os.path.join("assets", "audio", "se"),
        os.path.join("assets", "audio", "jingle"),
        os.path.join("assets", "audio", "bgm"),
    ]

    for d in dirs:
        os.makedirs(d, exist_ok=True)
        print(f"[DIR] ディレクトリ確認: {d}")

    print()

    # SE ファイルの生成
    se_files = [
        ("button_tap.wav", generate_button_tap, "ボタンタップ音(木琴風)"),
        ("string_hook.wav", generate_string_hook, "弦をかける音(ハープ風)"),
        ("string_unhook.wav", generate_string_unhook, "弦を外す音(柔らかいリリース)"),
        ("undo.wav", generate_undo, "元に戻す音(逆再生スウィープ)"),
        ("reset.wav", generate_reset, "リセット音(シマー/チャイム)"),
        ("panel_open.wav", generate_panel_open, "パネルを開く音(上昇ウーッシュ)"),
        ("panel_close.wav", generate_panel_close, "パネルを閉じる音(下降ウーッシュ)"),
        ("star_get.wav", generate_star_get, "星獲得音(スパークル)"),
        ("transition.wav", generate_transition, "画面遷移音(パッドスウィープ)"),
    ]

    print("[SE] SE ファイルを生成中...")
    print("-" * 40)
    for filename, generator, description in se_files:
        filepath = os.path.join("assets", "audio", "se", filename)
        audio = generator()
        save_wav(filepath, audio)
        # ファイルサイズを取得
        size_kb = os.path.getsize(filepath) / 1024
        print(f"  [OK] {filename:<22} ({size_kb:>6.1f} KB) - {description}")

    print()

    # ジングルファイルの生成
    jingle_files = [
        ("level_clear.wav", generate_level_clear, "レベルクリア ファンファーレ"),
        ("perfect_clear.wav", generate_perfect_clear, "パーフェクトクリア ファンファーレ"),
    ]

    print("[JINGLE] ジングルファイルを生成中...")
    print("-" * 40)
    for filename, generator, description in jingle_files:
        filepath = os.path.join("assets", "audio", "jingle", filename)
        audio = generator()
        save_wav(filepath, audio)
        size_kb = os.path.getsize(filepath) / 1024
        print(f"  [OK] {filename:<22} ({size_kb:>6.1f} KB) - {description}")

    print()
    print("[BGM] BGM ディレクトリは空の状態で作成されました。")
    print("      ユーザーが独自のBGMファイルを追加できます。")
    print()
    print("=" * 50)
    print("[完了] すべてのサウンドファイルの生成が完了しました！")
    print("=" * 50)


if __name__ == "__main__":
    main()
