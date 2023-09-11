import yaml
import os
from datasets import load_dataset
from transformers import pipeline

script_dir = os.path.dirname(os.path.abspath(__file__))
yaml_file_path = os.path.join(script_dir, 'config.yaml')
with open(yaml_file_path, 'r') as stream:
    data_loaded = yaml.safe_load(stream)

print(data_loaded['dataset'])


dataset = load_dataset(data_loaded['dataset'], "si", split="test")

classifier = pipeline("audio-classification", model=data_loaded['model'])
labels = classifier(dataset[0]["file"], top_k=5)
