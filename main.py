import yaml
import os
import time

import pyaudio
import wave

from datasets import load_dataset
from transformers import pipeline


script_dir = os.path.dirname(os.path.abspath(__file__))
def get_config():
  yaml_file_path = os.path.join(script_dir, 'config.yaml')
  with open(yaml_file_path, 'r') as stream:
      data_loaded = yaml.safe_load(stream)

  return data_loaded


def record_audio(duration):
  chunk = 1024  
  sample_format = pyaudio.paInt16
  channels = 1
  fs = 16000 
  seconds = duration
  filename = "/tmp/sample_output.wav"
  p = pyaudio.PyAudio()
  stream = p.open(format=sample_format,
                  channels=channels,
                  rate=fs,
                  frames_per_buffer=chunk,
                  input=True)

  frames = []
  for i in range(0, int(fs / chunk * seconds)):
      data = stream.read(chunk)
      frames.append(data)

  stream.stop_stream()
  stream.close()
  p.terminate()

  wf = wave.open(filename, 'wb')
  wf.setnchannels(channels)
  wf.setsampwidth(p.get_sample_size(sample_format))
  wf.setframerate(fs)
  wf.writeframes(b''.join(frames))
  wf.close()

  return filename


config = get_config()
dataset = load_dataset(config['dataset'], "si", split="test")
classifier = pipeline("audio-classification", model=config['model'])

while True:
  filename = record_audio(config['analyze-duration'])
  speaker_ids = [x['label'] for x in classifier(filename, top_k=5)]
  print(speaker_ids)

  if set(speaker_ids) & set(config['mute-speaker-ids']):
    os.system(f"osascript -e 'tell application \"Firefox\" to activate' -e 'repeat {config['skip-five-seconds-count']} times' -e 'tell application \"System Events\" to key code 124' -e 'end repeat'")

