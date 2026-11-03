"""Original procedural football sounds. Python stdlib; no samples or downloads.

Run offline with python3 tools/build_juicy_audio.py. Godot plays the WAV assets
using native spatial voices. Audio never consumes the match's random generator.
"""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'audio'
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
TAU = math.tau


def write(name, samples):
    peak = max(abs(x) for x in samples) or 1
    gain = .86 / peak
    values = [max(-32767, min(32767, round(x * gain * 32767))) for x in samples]
    with wave.open(str(OUT / (name + '.wav')), 'wb') as f:
        f.setparams((1, 2, RATE, len(values), 'NONE', 'not compressed'))
        f.writeframes(struct.pack('<' + 'h' * len(values), *values))


def impact(kind, variant):
    rng = random.Random(4312 + variant * 57 + sum(map(ord, kind)))
    length = {'pass':.11, 'shot':.19, 'power':.25, 'post':.48,
              'save':.18, 'tackle':.19, 'goal':.24}[kind]
    pitch = [1, .96, 1.045][variant]
    low = 0
    result = []
    for i in range(round(RATE * length)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low += .18 * (noise-low)
        high = noise-low
        phase = TAU * pitch * (57*t + (139-57)*.014*(1-math.exp(-t/.014)))
        if kind == 'post':
            value = .38 * high * math.exp(-t/.009)
            for frequency, level, decay in [(729,.46,.14),(1321,.26,.10),(1953,.17,.065),(2843,.10,.035)]:
                value += level * math.sin(TAU*frequency*pitch*t) * math.exp(-t/decay)
        elif kind == 'tackle':
            value = .8*low*math.exp(-t/.037) + .2*high*math.exp(-t/.012)
            value += .20*math.sin(TAU*92*pitch*t)*math.exp(-t/.026)
        elif kind == 'save':
            value = .65*low*math.exp(-t/.026)+.25*high*math.exp(-t/.009)
            value += .43*math.sin(phase)*math.exp(-t/.033)
        else:
            decay = {'pass':.026,'shot':.044,'power':.062,'goal':.048}[kind]
            value = .67*math.sin(phase)*math.exp(-t/decay)
            value += .19*math.sin(phase*2.13)*math.exp(-t/.014)
            value += (.44 if kind != 'goal' else .75)*high*math.exp(-t/.010)
            value += .18*low*math.exp(-t/.025)
            if kind == 'power': value += .23*math.sin(TAU*48*pitch*t)*math.exp(-t/.07)
            if kind == 'goal': value += .32*low*math.exp(-t/.067)
            value = math.tanh(value*1.35)
        value *= min(1, t/.0008) * min(1, (length-t)/.008)
        result.append(value)
    return result


def whistle(long):
    length = .63 if long else .21
    result = []
    rng = random.Random(514)
    for i in range(round(length*RATE)):
        t = i/RATE
        envelope = min(1,t/.012)*min(1,(length-t)/.045)
        if long: envelope *= .8+.2*math.sin(TAU*5*t)**2
        phase = TAU*2420*t+1.2*math.sin(TAU*18*t)
        value = .6*math.sin(phase)+.22*math.sin(phase*1.19)+.05*rng.uniform(-1,1)
        result.append(value*envelope)
    return result


def crowd(kind):
    length = {'ambience':8.,'chance':1.15,'cheer':2.9}[kind]
    rng = random.Random(895+sum(map(ord,kind)))
    voices = [(rng.uniform(104,236),rng.uniform(0,TAU),rng.uniform(.6,1.4)) for _ in range(9)]
    result = []
    slow = 0
    fast = 0
    for i in range(round(RATE*length)):
        t = i/RATE
        noise = rng.uniform(-1,1)
        slow += .014*(noise-slow)
        fast += .19*(noise-fast)
        breath = fast-slow
        voice = 0
        for base, phase, pace in voices:
            vibrato = .19*math.sin(TAU*4.1*t+phase)
            fundamental = TAU*base*t+phase+vibrato
            vowel = (.28*math.sin(fundamental)+.20*math.sin(fundamental*2)
                     +.17*math.sin(fundamental*3)+.11*math.sin(fundamental*5))
            if kind == 'ambience': modulation = .5+.5*math.sin(TAU*(pace*.15)*t+phase)
            else: modulation = .75+.25*math.sin(TAU*pace*t+phase)
            voice += vowel*modulation/9
        if kind == 'ambience':
            value = breath*.9+voice*.42
            # Smooth loop seam, independent of Godot's import configuration.
            edge = min(1,t/.10,(length-t)/.10)
            envelope = max(0,edge)*(.7+.2*math.sin(TAU*t/length))
        else:
            envelope = (1-math.exp(-t/.09))*math.exp(-t/(.43 if kind=='chance' else 1.15))
            envelope *= min(1,(length-t)/.18)
            value = breath*.85+voice*1.35
            if kind == 'cheer':
                for clap in [.12,.23,.42,.66,.94,1.29,1.68]:
                    if 0 <= t-clap < .025: value += noise*.26*math.exp(-(t-clap)/.006)
        result.append(value*envelope)
    return result


for kind in ['pass','shot','power','post','save','tackle','goal']:
    for variant in range(3): write(f'{kind}_{variant+1}',impact(kind,variant))
write('whistle',whistle(False))
write('whistle_long',whistle(True))
for kind in ['ambience','chance','cheer']: write('crowd_'+kind,crowd(kind))
print('JUICY_AUDIO_READY', len(list(OUT.glob('*.wav'))), 'original WAVs', sum(p.stat().st_size for p in OUT.glob('*.wav')), 'bytes')
