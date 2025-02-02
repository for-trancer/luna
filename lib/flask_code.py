from flask import Flask, request, jsonify,send_file
from transformers import AutoTokenizer, AutoModelForSequenceClassification, TextClassificationPipeline,AutoModelForTokenClassification,TokenClassificationPipeline
from diffusers import LCMScheduler,AutoPipelineForText2Image
import torch
import base64
from io import BytesIO
from PIL import Image
import threading
import time

app = Flask(__name__)

# Model Path
model_intent_path = 'XLMRoberta-Alexa-Intents-Classification' 
model_ner = 'XLMRoberta-Alexa-Intents-NER-NLU'
# Loading The Intents Model
tokenizer_intent = AutoTokenizer.from_pretrained(model_intent_path)
model_intent = AutoModelForSequenceClassification.from_pretrained(model_intent_path)
classifier_intent = TextClassificationPipeline(model=model_intent, tokenizer=tokenizer_intent)
# Loading The NER Model
tokenizer_ner = AutoTokenizer.from_pretrained(model_ner)
model_ner = AutoModelForTokenClassification.from_pretrained(model_ner)
classifier_ner = TokenClassificationPipeline(model=model_ner, tokenizer=tokenizer_ner)
# Loading the text-to-image generation model
model_id = "Lykon/dreamshaper-7"
local_lora_weights_path = "lcm-lora-sdv1-5"

# Load the pipeline for text-to-image generation with torch.float32 for CPU compatibility
pipe = AutoPipelineForText2Image.from_pretrained(model_id, torch_dtype=torch.float32)
pipe.scheduler = LCMScheduler.from_config(pipe.scheduler.config)
pipe.to("cpu")  

# Load and fuse the local LoRA weights
try:
    pipe.load_lora_weights(local_lora_weights_path)
    pipe.fuse_lora()
except ValueError as e:
    print("Error loading LoRA weights. Make sure PEFT is installed.")
    raise e



# Routes

# Intent Identification
@app.route('/predict_intent', methods=['POST'])
def predict_intent():
    # Get the JSON payload from the request
    data = request.get_json()
    text = data.get('text', '')

    if not text:
        return jsonify({"error": "No text provided"}), 400

    # Call the classifier function (ensure this is not async)
    prediction = classifier_intent(text)

    print(prediction)
    # Return the predictions as a response
    return jsonify(prediction)

# Image Generation
@app.route('/generate_image', methods=['POST'])
def generate_image():
    # Get the JSON payload from the request
    data = request.get_json()
    prompt = data.get('text', '')

    # Generate the image
    with torch.no_grad():
        image = pipe(prompt=prompt, num_inference_steps=5, guidance_scale=0).images[0]

    # Convert the image to a base64 string
    image.show()
    buffered = BytesIO()
    image.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')

    # Return the image as a base64 string
    response = jsonify({"image": f"data:image/png;base64,{img_str}"})
    response.headers['Connection'] = 'keep-alive'
    return response

# NER
@app.route('/get_data', methods=['POST'])
def get_data():
    # Get the JSON payload from the request
    data = request.get_json()
    text = data.get('text', '')

    if not text:
        return jsonify({"error": "No text provided"}), 400

    # Call the classifier function (ensure this is not async)
    data = classifier_ner(text)
    filtered_data = [
        {
            'entity': pred['entity'],
            'index': pred['index'],
            'word': pred['word'],
            'start': pred['start'],
            'end': pred['end']
        }
        for pred in data
    ]
    print(filtered_data)

    # Return the predictions as a response
    return jsonify(filtered_data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False) 