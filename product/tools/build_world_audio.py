"""Rebuild original deterministic transition/portal sound layers. No runtime dependency."""
from pathlib import Path
import json,subprocess,hashlib
import numpy as np
RATE=44100
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/audio/world_effects"
def write(name,signal):
 signal=np.asarray(signal);signal=signal/max(1,float(np.max(np.abs(signal)))/0.75)
 stereo=np.column_stack([signal,np.roll(signal,173)*0.98]).astype("<f4")
 subprocess.run(["ffmpeg","-v","error","-y","-f","f32le","-ar",str(RATE),"-ac","2","-i","pipe:0","-c:a","libvorbis","-q:a","7",str(OUT/(name+".ogg"))],input=stereo.tobytes(),check=True)
def noise(seconds,seed):
 rng=np.random.default_rng(seed);n=int(RATE*seconds);f=np.fft.rfftfreq(n,1/RATE)
 spectrum=np.fft.rfft(rng.normal(0,1,n));weight=np.exp(-((f-700)/950)**2)*(f>80)
 x=np.fft.irfft(spectrum*weight,n=n);return x/max(0.01,float(np.max(np.abs(x))))
def build():
 OUT.mkdir(parents=True,exist_ok=True)
 t=np.arange(RATE*8)/RATE
 hum=0.10*np.sin(2*np.pi*82*t)+0.045*np.sin(2*np.pi*123*t)+0.025*np.sin(2*np.pi*246*t)
 write("portal_hum",hum+noise(8,812)*0.05)
 t=np.arange(RATE*10)/RATE
 swell=np.sin(np.pi*t/10)**2
 write("chapter_passage",swell*(noise(10,813)*0.4+0.09*np.sin(2*np.pi*(80*t+6*t*t))))
 score=np.zeros_like(t)
 for when,freq in [(0,196),(1.1,246.94),(2.2,293.66),(3.8,392),(5.5,293.66),(7.2,246.94)]:
  d=np.maximum(0,t-when);env=np.where(t>=when,(1-np.exp(-d*6))*np.exp(-d*0.7),0)
  score+=env*(np.sin(2*np.pi*freq*t)+0.2*np.sin(2*np.pi*2*freq*t))*0.12
 write("chapter_farewell",score* np.minimum(1,(10-t)/0.5)+noise(10,814)*0.015*swell)
 t=np.arange(int(RATE*0.55))/RATE
 write("sword_whirl",noise(0.55,815)*np.sin(np.pi*t/0.55)**1.5*0.55)
 files={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in OUT.glob("*.ogg")}
 (OUT/"SOURCE.json").write_text(json.dumps({"origin":"Original deterministic DSP created for this project; no external recordings","builder":"tools/build_world_audio.py","license":"CC0-1.0","files":files},indent=2)+"\n")
if __name__=="__main__":build()
