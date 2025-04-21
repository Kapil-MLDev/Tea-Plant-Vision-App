
# 🌿 Tea Plant Vision App
Innovative Machine Learning Solutions for Early Detection of Tea Plant Diseases


This project is my final year BSc (Hons.) Information Technology project, focused on helping farmers and agricultural professionals detect tea plant diseases early using a machine learning-powered mobile app.

## Project Description
This project is a mobile application built with **Flutter** and powered by a **Deep learning CNN model** for detecting common tea plant diseases. Users can capture or upload images of tea leaves, and the app will identify potential diseases, display related symptoms, solutions and recommend remedies. The backend is powered by a **Flask API** that serves the trained model and processes image inputs in real-time.

## 🚀 Project Objective

To build a mobile application using Flutter that allows users to scan tea plant leaves and get real-time predictions about possible diseases using a Convolutional Neural Network (CNN) model.

## 🧠 Technologies Used

- Flutter (Frontend – Mobile UI)
- Python + TensorFlow/Keras (Backend – CNN Model)
- Flask (API for model integration)
- Google Colab / Jupyter (Model training)
- GitHub (Version Control)
- Language: Python, Dart
- anaconda navigator environment
  
## 🎯 Key Features

- 📷 Real-time image scanning (like Google Lens)
- 🤖 CNN-based disease prediction
- 📊 Display disease name, symptoms, and suggested treatments
- 📁 Simple and clean UI
- 🔗 Integrated with backend API
- 📷 Upload from gallery or use camera
- Designed to support sustainable agriculture for tea farmers

## 📷 Screenshots

| Home Screen | Prediction Screen |
|-------------|-------------------|
| ![Home](media) | ![Result](media) |

## 🛠️ How to Run the Project

### 🔹 Frontend (Flutter)
```bash
cd tea_ui
flutter pub get
flutter run
```


### 🔹 Backend (Flask API)
```bash
cd tea_backend
pip install -r requirements.txt
python app.py
```