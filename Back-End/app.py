import numpy as np
import tensorflow as tf
from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image
import io
import keras.utils as image

app = Flask(__name__)
CORS(app)

# Load model
try:
    model = tf.keras.models.load_model('my_model.keras', compile=False)
    print("Model loaded successfully")
except Exception as e:
    print(f"Model load error: {e}")
    exit(1)

# Disease configuration
disease_classes = ["gray_blight", "healthy", "helopeltis", "red_spot"]

solutions = {
    "gray_blight": {
        "symptoms": ["Grayish-brown leaf spots", "Premature leaf drop"],
        "solutions": {
            "cultural": ["Prune infected leaves", "Improve air circulation"],
            "chemical": ["Carbendazim 50% WP", "Copper Oxychloride (3 g/L)"],
            "bio_control": ["Trichoderma viride"]
        }
    },
    "healthy": {
        "symptoms": ["No visible symptoms"],
        "solutions": {"general": ["Maintain regular care"]}
    },
    "helopeltis": {
        "symptoms": ["Brown necrotic patches", "Leaf curling", "Blackening"],
        "solutions": {
            "cultural": ["Remove affected parts", "Encourage natural predators"],
            "chemical": ["Imidacloprid 17.8 SL", "Thiamethoxam 25 WG"],
            "organic": ["Neem oil (3-5 ml/L)", "Garlic-Chili extract"],
            "bio_control": ["Beauveria bassiana"]
        }
    },
    "red_spot": {
        "symptoms": ["Reddish-orange circular spots", "Leaf drop"],
        "solutions": {
            "cultural": ["Prune for better air circulation", "Avoid excess irrigation"],
            "chemical": ["Copper Oxychloride (3 g/L)", "Bordeaux Mixture (1%)"],
            "organic": ["Baking Soda Spray (1 tsp/L water + mild soap)"],
            "bio_control": ["Pseudomonas fluorescens (5 g/L)"]
        }
    }
}

@app.route('/predict', methods=['POST'])
def predict():
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file uploaded"}), 400

        # Process image
        file = request.files['file']
        img = Image.open(io.BytesIO(file.read())).convert('RGB')
        img = img.resize((128, 128))
        img_array = image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)

        # Predict
        preds = model.predict(img_array)
        class_idx = np.argmax(preds[0])
        disease = disease_classes[class_idx]

        # Verify valid disease
        if disease not in solutions:
            raise ValueError(f"Unknown disease: {disease}")

        # Build response
        return jsonify({
            "message": "Prediction successful",
            "disease": disease,
            "symptoms": solutions[disease]["symptoms"],
            "treatment": solutions[disease]["solutions"],
            "accuracy": float(preds[0][class_idx])
        })

    except IndexError as e:
        print(f"Index error: Model returned invalid class {class_idx}")
        return jsonify({"error": "Model prediction error"}), 500
    except KeyError as e:
        print(f"Key error: {str(e)} in solutions dictionary")
        return jsonify({"error": "Configuration error"}), 500
    except Exception as e:
        print(f"General error: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)