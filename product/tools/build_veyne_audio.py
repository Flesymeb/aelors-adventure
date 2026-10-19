"""Offline, deterministic creature/elemental sound design; no runtime Python.

Source recordings: Darsycho's CC0 Monster snarls / Big scary troll sounds and
AntumDeluge's CC0 Fire Crackling (see assets/audio/veyne/SOURCE.json).
All electric, wind, stone and noise layers are authored procedural signals.
Requires numpy, scipy and FFmpeg only when rebuilding these Ogg assets.
"""
from pathlib import Path
import hashlib,json,subprocess,wave
import numpy as np
from scipy.signal import butter,sosfilt,resample_poly

RATE=44100
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio/veyne'
RNG=np.random.default_rng(8619)

def decode(path):
 r=subprocess.run(['ffmpeg','-v','error','-i',str(path),'-ac','1','-ar',str(RATE),'-f','f32le','-'],capture_output=True,check=True)
 return np.frombuffer(r.stdout,dtype='<f4').astype(float)

def noise(seconds,low=60,high=6000):
 x=RNG.standard_normal(round(seconds*RATE))
 return sosfilt(butter(3,[low,high],btype='bandpass',fs=RATE,output='sos'),x)

def env(x,attack=.025,release=.18):
 x=np.array(x,dtype=float,copy=True)
 a=min(len(x),round(attack*RATE));r=min(len(x),round(release*RATE))
 if a:x[:a]*=np.linspace(0,1,a)**1.6
 if r:x[-r:]*=np.linspace(1,0,r)**1.5
 return x

def strongest(x,seconds):
 n=min(len(x),round(seconds*RATE));hop=RATE//8
 starts=range(0,max(1,len(x)-n),hop)
 start=max(starts,key=lambda i:np.mean(x[i:i+n]**2))
 return env(x[start:start+n],.05,.2)

def pitch(x,factor):
 return resample_poly(x,1000,round(1000*factor))

def mix(*layers):
 size=max(len(x) for x in layers);v=np.zeros(size)
 for x in layers:v[:len(x)]+=x
 return v

def echo(x,delay=.085,gain=.16):
 result=np.pad(x,(0,round(RATE*delay*3)))
 for step in range(1,4):
  start=round(RATE*delay*step);result[start:start+len(x)]+=x*gain**step
 return result

def emit(name,x,description):
 x=env(x,.012,.09);x-=np.mean(x)
 peak=np.max(np.abs(x));assert peak>1e-5
 x=x/peak*.84
 path=OUT/(name+'.ogg');raw=OUT/(name+'.wav')
 with wave.open(str(raw),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes((np.clip(x,-1,1)*32767).astype('<i2').tobytes())
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(raw),'-c:a','libvorbis','-q:a','5',str(path)],check=True)
 raw.unlink()
 decoded=decode(path)
 return {'file':path.name,'description':description,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'duration_seconds':round(len(decoded)/RATE,4),'peak_dbfs':round(float(20*np.log10(np.max(np.abs(decoded))+1e-12)),2),'rms_dbfs':round(float(20*np.log10(np.sqrt(np.mean(decoded**2))+1e-12)),2),'source':'CC0 recordings plus original procedural layers' if 'roar' in name or name=='fire_breath' else 'original procedural sound design'}

def main():
 OUT.mkdir(parents=True,exist_ok=True)
 monster=decode(OUT/'sources/monster_attack.ogg');troll=decode(OUT/'sources/troll_roars.ogg');fire=decode(OUT/'sources/fire_crackle.ogg')
 voice=pitch(strongest(troll,2.2),.70);voice2=pitch(strongest(monster,2.0),.64)
 vtime=np.arange(len(voice))/RATE
 rumble=np.sin(2*np.pi*(44*vtime-3*vtime*vtime))*.12
 records=[]
 def add(n,x,d):records.append(emit(n,x,d))
 add('roar_reveal',echo(mix(voice*.88,voice2*.35,env(rumble)),.12,.24),'Layered low creature roar for the dragon entrance')
 add('roar_phase',echo(mix(voice2,noise(len(voice2)/RATE,40,220)*.12),.10,.20),'Distinct strained roar when the dragon enters phase two')
 dying=pitch(strongest(monster,2.6),.58);dying*=np.linspace(1,.05,len(dying))**.7
 add('death_roar',echo(dying,.14,.23),'A descending last roar and breath for the death presentation fallback')
 t=np.arange(round(.9*RATE))/RATE
 charge=env(noise(.9,180,6500)*np.linspace(.08,1,len(t))**1.4,.02,.04)
 charge*=.65+.35*np.sin(2*np.pi*31*t)**2
 add('lightning_charge',charge,'Crackling electrical windup, separate from the discharge')
 t=np.arange(round(1.4*RATE))/RATE
 crack=noise(1.4,200,13000)*np.exp(-t*4)
 for offset in (.045,.11,.19,.32):
  index=int(offset*RATE);crack[index:index+900]+=noise(900/RATE,800,15000)*.7
 thunder=noise(1.4,35,210)*np.exp(-t*2)*1.9
 add('lightning',echo(mix(crack,thunder),.09,.19),'Broadband electrical snap followed by a low thunder roll')
 t=np.arange(round(.85*RATE))/RATE
 add('fire_inhale',env(noise(.85,120,1800)*np.linspace(.05,1,len(t)),.15,.04),'Audible air intake before fire breath')
 length=round(1.3*RATE);firebody=np.resize(fire,length)
 rush=noise(1.3,55,4200);t=np.arange(length)/RATE
 flame=firebody*.6+rush*(.6+.14*np.sin(t*29)+.1*np.sin(t*71))
 # A short edge fade makes looping stable without repeated attack transients.
 add('fire_breath',env(flame,.045,.045),'Crackling fire and broad rushing flame, looped only during active breath')
 add('charge_warning',mix(env(noise(.65,45,200),.06,.24)*2,env(pitch(strongest(monster,.55),.8))*.4),'Low body preparation and short creature growl before a charge')
 t=np.arange(round(1.0*RATE))/RATE
 add('charge',env(noise(1.0,80,3800)*(np.sin(np.pi*np.clip(t,0,1))**.6),.03,.16),'Heavy rushing body and scraping air during forward charge')
 t=np.arange(round(1.1*RATE))/RATE
 add('wing_takeoff',env(noise(1.1,75,2400)*(0.22+np.sin(t*9)**8),.05,.25),'Two broad leathery wing beats during takeoff')
 t=np.arange(round(.8*RATE))/RATE
 add('dive',env(noise(.8,140,7500)*np.linspace(.08,1,len(t))**1.4,.02,.08),'Rapid descending air rush during the committed dive')
 t=np.arange(round(1.6*RATE))/RATE
 impact=noise(1.6,28,180)*np.exp(-t*4.8)*2.2
 impact+=noise(1.6,300,5000)*np.exp(-t*5)*.8
 for offset in (.18,.31,.49,.72):
  start=round(offset*RATE);count=round(.12*RATE)
  impact[start:start+count]+=env(noise(count/RATE,400,6500),.002,.10)*.35
 add('landing',echo(impact,.11,.18),'Grounded stone impact with low body weight and settling rubble')
 t=np.arange(round(.5*RATE))/RATE
 add('claw',env(noise(.5,250,6500)*np.sin(np.pi*t/.5),.02,.12),'Short claw and wing swish, distinct from lightning and flame')
 add('rift_warning',env(noise(.7,400,7000)*np.linspace(.05,.9,round(.7*RATE)),.04,.06),'Growing electrical rift crackle')
 t=np.arange(round(.65*RATE))/RATE
 add('rift_contact',echo(env(noise(.65,70,9000)*np.exp(-t*7),.004,.1),.065,.14),'Brief magical crack on a resolved rift contact')
 source_records=json.loads((OUT/'sources/sources.json').read_text())
 manifest={'schema_version':1,'kind':'dragon_voice_and_elemental_combat_audio','sample_rate':RATE,'channels':1,'recording_sources':source_records,'authored_layers':'Deterministic original noise, wind, electrical and stone-impact synthesis; no UI beep substitutions','processing':'Source selection, pitch lowering, layering, edge fades, restrained echoes; Vorbis q5; headroom 0.84 peak before encode','builder':'tools/build_veyne_audio.py','files':records}
 (OUT/'SOURCE.json').write_text(json.dumps(manifest,indent=2)+'\n')
 (OUT/'LICENSES.md').write_text('''# Veyne combat audio\n\nCreature recording sources by Darsycho:\n- Monster snarls: https://opengameart.org/content/monster-snarls\n- Big scary troll sounds: https://opengameart.org/content/big-scary-troll-sounds\n\nFire Crackling by AntumDeluge:\n- https://opengameart.org/content/fire-crackling/\n\nAll three source packs declare CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/\nCredit is retained voluntarily. These recordings are pitch-shifted, selected, layered and edited for the dragon.\nAdditional electrical, wind and stone layers are original procedural audio authored for this project; the project license applies to that authoring.\nSee SOURCE.json for source URLs, SHA-256 hashes, processing and each resulting clip.\n''')
 print(json.dumps({'generated_clips':len(records),'total_bytes':sum((OUT/r['file']).stat().st_size for r in records),'files':records},indent=2))

if __name__=='__main__':main()
