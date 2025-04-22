import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'animated_splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  List<CameraDescription>? cameras;
  Map<String, dynamic>? _predictionResult;
  final ImagePicker _picker = ImagePicker();
  String? _cameraError;
  Uint8List? _capturedImageBytes;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _serverHost = '10.0.2.2'; // Default for Android emulator
  bool _isEmulator = false;

  static const Map<String, Map<String, dynamic>> diseaseData = {
    'gray_blight': {
      'symptoms': ["Grayish-brown leaf spots", "Premature leaf drop"],
      'solutions': {
        'cultural': ["Prune infected leaves", "Improve air circulation"],
        'chemical': ["Carbendazim 50% WP", "Copper Oxychloride (3 g/L)"],
        'bio_control': ["Trichoderma viride"]
      }
    },
    'helopeltis': {
      'symptoms': ["Brown necrotic patches", "Leaf curling", "Blackening"],
      'solutions': {
        'cultural': ["Remove affected parts", "Encourage natural predators"],
        'chemical': ["Imidacloprid 17.8 SL", "Thiamethoxam 25 WG"],
        'organic': ["Neem oil (3-5 ml/L)", "Garlic-Chili extract"],
        'bio_control': ["Beauveria bassiana"]
      }
    },
    'red_spot': {
      'symptoms': ["Reddish-orange circular spots", "Leaf drop"],
      'solutions': {
        'cultural': [
          "Prune for better air circulation",
          "Avoid excess irrigation"
        ],
        'chemical': ["Copper Oxychloride (3 g/L)", "Bordeaux Mixture (1%)"],
        'organic': ["Baking Soda Spray (1 tsp/L water + mild soap)"],
        'bio_control': ["Pseudomonas fluorescens (5 g/L)"]
      }
    },
    'healthy': {
      'symptoms': ["The tea leaves good for health"],
      'solutions': {
        'cultural': ["Maintain regular pruning", "Ensure proper irrigation"],
        'general': ["Continue monitoring leaf health"]
      }
    }
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _determineServerHost();
  }

  Future<void> _determineServerHost() async {
    if (kIsWeb) {
      _serverHost = 'localhost';
    } else if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _isEmulator = !androidInfo.isPhysicalDevice;
      _serverHost = _isEmulator
          ? '10.0.2.2'
          : '192.168.8.148:5000'; // REPLACE WITH local IP
    } else if (Platform.isIOS) {
      _serverHost = '127.0.0.1:5000';
    }
    print('Server host set to: $_serverHost | Emulator: $_isEmulator');
  }

  Future<void> _initializeCamera() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
          if (!status.isGranted) {
            throw Exception('Camera permission denied');
          }
        }
      }

      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        throw Exception("No cameras available on this device");
      }

      _cameraController = CameraController(
        cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _cameraError = null;
      });
    } catch (e) {
      setState(() {
        _cameraError = "Camera initialization failed: ${e.toString()}";
        _isCameraInitialized = false;
      });
      print('Camera Error: $_cameraError');
    }
  }

  Future<void> _refreshApp() async {
    setState(() {
      _predictionResult = null;
      _capturedImageBytes = null;
      _cameraError = null;
    });
    await _initializeCamera();
  }

  Future<void> _captureImage() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (!_isCameraInitialized || _cameraController == null) {
        await _initializeCamera();
        if (!_isCameraInitialized) return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      final XFile image = await _cameraController!.takePicture();

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        _capturedImageBytes = bytes;
        await _sendImageToServer(bytes);
      } else {
        final File imageFile = File(image.path);
        _capturedImageBytes = await imageFile.readAsBytes();
        await _sendImageToServer(imageFile);
      }
    } catch (e) {
      setState(() {
        _cameraError = "Error capturing image: ${e.toString()}";
      });
      print('Capture Error: $_cameraError');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _isProcessing = true);

      if (kIsWeb) {
        final result =
            await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.single.bytes != null) {
          _capturedImageBytes = result.files.single.bytes;
          await _sendImageToServer(result.files.single.bytes!);
        }
      } else {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final File imageFile = File(image.path);
          _capturedImageBytes = await imageFile.readAsBytes();
          await _sendImageToServer(imageFile);
        }
      }
    } catch (e) {
      setState(() {
        _cameraError = "Error picking image: ${e.toString()}";
      });
      print('Gallery Error: $_cameraError');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _sendImageToServer(dynamic imageData) async {
    try {
      final uri = Uri.parse('http://$_serverHost:5000/predict');
      print('Attempting to connect to: $uri');

      final request = http.MultipartRequest('POST', uri);

      if (imageData is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imageData,
          filename: 'image.jpg',
        ));
      } else if (imageData is File) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imageData.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final prediction = jsonDecode(responseBody);
        _handlePredictionResponse(prediction);
      } else {
        throw Exception("Server error: ${response.statusCode}\n$responseBody");
      }
    } catch (e) {
      print("Server Connection Error: $e");
      setState(() {
        _cameraError = "Connection failed to $_serverHost:5000\n"
            "Ensure:\n"
            "1. Flask server is running\n"
            "2. Correct IP address is set\n"
            "3. Devices are on same network\n"
            "Error: ${e.toString()}";
      });
    }
  }

  void _handlePredictionResponse(Map<String, dynamic> prediction) {
    final disease = prediction['disease'];
    if (!diseaseData.containsKey(disease)) {
      throw Exception('Unknown disease: $disease');
    }

    setState(() {
      _predictionResult = {
        'disease': disease,
        'accuracy': prediction['accuracy'],
        'data': diseaseData[disease]
      };
      _cameraError = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Tea Plant Disease AI Detection"),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SplashScreen()),
          ),
          tooltip: 'Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshApp,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCameraPreview(),
            _buildControlButtons(),
            if (_isProcessing) const LinearProgressIndicator(),
            if (_predictionResult != null) _buildDiseaseCard(),
            if (_cameraError != null) _buildErrorDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: _cameraError != null
          ? const Center(
              child: Icon(Icons.error,
                  size: 50, color: Color.fromARGB(255, 235, 233, 233)))
          : _isCameraInitialized &&
                  _cameraController != null &&
                  _capturedImageBytes == null
              ? AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                )
              : _capturedImageBytes != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.memory(_capturedImageBytes!,
                          fit: BoxFit.contain),
                    )
                  : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _isProcessing ? null : _pickImageFromGallery,
            tooltip: 'Gallery',
            child: const Icon(Icons.photo_library),
          ),
          FloatingActionButton(
            onPressed: _isProcessing ? null : _captureImage,
            tooltip: 'Capture',
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _cameraError!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildDiseaseCard() {
    final data = _predictionResult!['data'] as Map<String, dynamic>;
    final diseaseName =
        _predictionResult!['disease'].toString().replaceAll('_', ' ');

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diseaseName.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: ${(_predictionResult!['accuracy'] * 100).toStringAsFixed(2)}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text('SYMPTOMS:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...data['symptoms'].map((s) => _buildBulletPoint(s)).toList(),
            const SizedBox(height: 16),
            const Text('SOLUTIONS:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...data['solutions']
                .entries
                .map((e) => _buildSolutionTile(e))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildSolutionTile(MapEntry<String, List<dynamic>> solution) {
    return ExpansionTile(
      title: Text(
        solution.key.toUpperCase(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      children: solution.value
          .map((item) => ListTile(
                dense: true,
                title: Text('• $item'),
                visualDensity: const VisualDensity(vertical: -4),
              ))
          .toList(),
    );
  }
}
