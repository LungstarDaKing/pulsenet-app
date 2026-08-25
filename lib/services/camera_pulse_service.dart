import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraPulseService {
  CameraPulseService();

  // Stream for emitting BPM values as they're calculated
  final _bpmController = StreamController<double>.broadcast();
  Stream<double> get bpmStream => _bpmController.stream;

  // Camera controller
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isStreaming = false;
  bool _isMeasuring = false;

  // Measurement state
  int _measurementSeconds = 0;
  static const int _measurementDurationSeconds = 18; // 18 seconds for stable reading
  Timer? _measurementTimer;
  List<double> _redValues = []; // Store red channel intensity values
  List<double> _timestamps = []; // Store timestamps for each sample

  // Signal processing parameters
  static const int _sampleRateHz = 15; // Target sampling rate from camera
  static const int _bufferSize = 150; // 10 seconds of data at 15 Hz
  static const double _lowCutoff = 0.5; // Hz - minimum heart rate ~30 BPM
  static const double _highCutoff = 4.0; // Hz - maximum heart rate ~240 BPM

  // Initialize the camera
  Future<bool> initializeCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();

      // Prefer back flash if available, otherwise front
      CameraDescription? selectedCamera;

      // Try to find a back camera with flash first
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      // If no back camera, use front
      if (selectedCamera == null && cameras.isNotEmpty) {
        selectedCamera = cameras.first;
      }

      if (selectedCamera == null) {
        return false;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.low, // Low resolution for faster processing
        enableAudio: false,
      );

      // Initialize the camera
      await _cameraController!.initialize();

      // Start image stream
      _cameraController!.startImageStream(_processFrame);
      _isInitialized = true;
      _isStreaming = true;

      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return false;
    }
  }

  // Process each frame from the camera
  Future<void> _processFrame(CameraImage image) async {
    if (!_isMeasuring) return;

    try {
      // Extract luminance/red channel data from the image
      // For simplicity, we'll calculate average intensity from the center region
      // where the user's fingertip would be

      final int width = image.width;
      final int height = image.height;

      // Calculate region of interest (center 40% of image)
      final int roiStartX = (width * 0.3).round();
      final int roiEndX = (width * 0.7).round();
      final int roiStartY = (height * 0.3).round();
      final int roiEndY = (height * 0.7).round();

      double totalIntensity = 0;
      int pixelCount = 0;

      // Different image formats require different handling
      if (image.format.group == ImageFormatGroup.yuv420) {
        // For YUV420 format, we'll approximate using the Y (luminance) plane
        final Plane plane = image.planes[0];
        final int bytesPerRow = plane.bytesPerRow;

        for (int y = roiStartY; y < roiEndY; y++) {
          final int rowStart = y * bytesPerRow;
          for (int x = roiStartX; x < roiEndX; x++) {
            final int pixelIndex = rowStart + x;
            if (pixelIndex < plane.bytes.length) {
              // Y plane contains luminance (brightness) which correlates with blood volume
              final int yValue = plane.bytes[pixelIndex];
              totalIntensity += yValue.toDouble();
              pixelCount++;
            }
          }
        }
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        // For BGRA format
        final Plane plane = image.planes[0];
        final int bytesPerRow = plane.bytesPerRow;

        for (int y = roiStartY; y < roiEndY; y++) {
          final int rowStart = y * bytesPerRow;
          for (int x = roiStartX; x < roiEndX; x++) {
            final int pixelIndex = (rowStart + x * 4); // 4 bytes per pixel (BGRA)
            if (pixelIndex + 2 < plane.bytes.length) {
              // Extract R, G, B values (BGRA order: blue, green, red, alpha)
              // We use the red channel (third byte)
              final int r = plane.bytes[pixelIndex + 2];
              totalIntensity += r.toDouble();
              pixelCount++;
            }
          }
        }
      } else {
        // Skip unsupported formats
        return;
      }

      if (pixelCount > 0) {
        final double avgIntensity = totalIntensity / pixelCount;

        // Store the sample with timestamp
        final double timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;
        _redValues.add(avgIntensity);
        _timestamps.add(timestamp);

        // Keep buffer at reasonable size
        if (_redValues.length > _bufferSize) {
          _redValues.removeRange(0, _redValues.length - _bufferSize);
          _timestamps.removeRange(0, _timestamps.length - _bufferSize);
        }

        // Process signal when we have enough data
        if (_redValues.length >= 30) { // Process after ~2 seconds of data
          _processSignal();
        }
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    }
  }

  // Process the PPG signal to extract heart rate
  void _processSignal() {
    if (_redValues.length < 10) return;

    try {
      // 1. Detrend the signal (remove slow fluctuations)
      List<double> detrended = _detrendSignal(_redValues);

      // 2. Apply bandpass filter to isolate heart rate frequencies
      List<double> filtered = _bandpassFilter(detrended);

      // 3. Detect peaks in the filtered signal
      List<int> peaks = _detectPeaks(filtered);

      // 4. Calculate heart rate from peak intervals
      if (peaks.length >= 2) {
        List<double> intervals = [];
        for (int i = 1; i < peaks.length; i++) {
          // Convert sample indices to time intervals
          double time1 = _timestamps[peaks[i-1]];
          double time2 = _timestamps[peaks[i]];
          intervals.add(time2 - time1); // seconds between peaks
        }

        if (intervals.isNotEmpty) {
          // Calculate median interval to reduce outlier impact
          intervals.sort();
          double medianInterval;
          if (intervals.length.isOdd) {
            medianInterval = intervals[intervals.length ~/ 2];
          } else {
            medianInterval = (intervals[intervals.length ~/ 2 - 1] +
                            intervals[intervals.length ~/ 2]) / 2;
          }

          // Convert interval to BPM
          if (medianInterval > 0) {
            double bpm = 60.0 / medianInterval;

            // Only accept physiologically plausible values
            if (bpm >= 30 && bpm <= 220) {
              _bpmController.add(bpm);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing signal: $e');
    }
  }

  // Remove linear trend from signal
  List<double> _detrendSignal(List<double> signal) {
    if (signal.length < 2) return List.from(signal);

    int n = signal.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += signal[i];
      sumXY += i * signal[i];
      sumXX += i * i;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    List<double> detrended = [];
    for (int i = 0; i < n; i++) {
      double expected = slope * i + intercept;
      detrended.add(signal[i] - expected);
    }

    return detrended;
  }

  // Simple bandpass filter implementation
  List<double> _bandpassFilter(List<double> signal) {
    if (signal.length < 3) return List.from(signal);

    // Simple moving average for smoothing
    int windowSize = 5;
    List<double> smoothed = List.filled(signal.length, 0.0);

    for (int i = 0; i < signal.length; i++) {
      double sum = 0;
      int count = 0;
      int halfWindow = windowSize ~/ 2;

      for (int j = -halfWindow; j <= halfWindow; j++) {
        int index = i + j;
        if (index >= 0 && index < signal.length) {
          sum += signal[index];
          count++;
        }
      }

      smoothed[i] = sum / count;
    }

    // High-pass component (remove low frequency drift)
    List<double> highPassed = [];
    for (int i = 1; i < smoothed.length; i++) {
      highPassed.add(smoothed[i] - smoothed[i-1]);
    }

    // Pad to maintain length
    highPassed.insert(0, 0.0);

    return highPassed;
  }

  // Simple peak detection
  List<int> _detectPeaks(List<double> signal) {
    if (signal.length < 3) return [];

    List<int> peaks = [];
    double threshold = 0.5; // Adjust based on signal amplitude

    // Find local maxima
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i-1] &&
          signal[i] > signal[i+1] &&
          signal[i] > threshold) {
        peaks.add(i);
      }
    }

    // Filter peaks that are too close together (minimum 0.3s between beats at 200 BPM)
    List<int> filteredPeaks = [];
    int minSamplesBetweenPeaks = (_sampleRateHz * 0.3).round();

    for (int i = 0; i < peaks.length; i++) {
      if (i == 0 ||
          (peaks[i] - (filteredPeaks.isEmpty ? -999 : filteredPeaks.last)) >= minSamplesBetweenPeaks) {
        filteredPeaks.add(peaks[i]);
      }
    }

    return filteredPeaks;
  }

  // Start measuring heart rate
  Future<bool> startMeasurement() async {
    if (!_isInitialized) {
      bool success = await initializeCamera();
      if (!success) return false;
    }

    // Reset measurement state
    _measurementSeconds = 0;
    _redValues.clear();
    _timestamps.clear();
    _isMeasuring = true;

    // Start countdown timer
    _measurementTimer?.cancel();
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _measurementSeconds++;
      if (_measurementSeconds >= _measurementDurationSeconds) {
        stopMeasurement();
      }
    });

    return true;
  }

  // Stop measuring heart rate
  void stopMeasurement() {
    _isMeasuring = false;
    _measurementTimer?.cancel();

    // Stop camera stream but keep initialized for potential reuse
    if (_isStreaming && _cameraController != null) {
      _cameraController!.stopImageStream();
      _isStreaming = false;
    }
  }

  // Release camera resources
  Future<void> dispose() async {
    stopMeasurement();
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.dispose();
    }
    _cameraController = null;
    _isInitialized = false;
    _bpmController.close();
  }

  // Get current measurement progress (0.0 to 1.0)
  double get progress =>
      _measurementDurationSeconds > 0
      ? _measurementSeconds / _measurementDurationSeconds
      : 0.0;

  // Get remaining time in seconds
  int get remainingTime =>
      (_measurementDurationSeconds - _measurementSeconds).clamp(0, _measurementDurationSeconds);

  // Check if currently measuring
  bool get isMeasuring => _isMeasuring;
}