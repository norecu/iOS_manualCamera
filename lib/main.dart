import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ManualCameraApp());
}

class ManualCameraApp extends StatelessWidget {
  const ManualCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IOS Camera',
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  static const MethodChannel _cameraChannel = MethodChannel('ios-camera');

  bool _isCapturing = false;

  double _iso = 100;
  double _ev = 0.0;
  double _focus = 0.0;
  double _zoom = 1.0;

  int _shutterIndex = 5;

  final List<double> _shutterSpeeds = [
    1 / 1000,
    1 / 500,
    1 / 250,
    1 / 125,
    1 / 60,
    1 / 30,
    1 / 15,
    1 / 8,
    1 / 4,
    1 / 2,
    1.0,
  ];

  String get _shutterLabel {
    final seconds = _shutterSpeeds[_shutterIndex];

    if (seconds >= 1.0) {
      return '${seconds.toStringAsFixed(0)}s';
    }

    return '1/${(1 / seconds).round()}';
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      await _cameraChannel.invokeMethod('capturePhoto');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진이 저장되었습니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '사진 촬영 실패: '
            '${error.message ?? '알 수 없는 오류'}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _setISO(double value) async {
    try {
      await _cameraChannel.invokeMethod('setISO', value);

      if (!mounted) {
        return;
      }

      setState(() {
        _iso = value;
      });
    } on PlatformException catch (error) {
      debugPrint('ISO 변경 실패: ${error.message}');
    }
  }

  Future<void> _setEV(double value) async {
    try {
      await _cameraChannel.invokeMethod('setEV', value);

      if (!mounted) {
        return;
      }

      setState(() {
        _ev = value;
      });
    } on PlatformException catch (error) {
      debugPrint('EV 변경 실패: ${error.message}');
    }
  }

  Future<void> _setShutter(int index) async {
    final seconds = _shutterSpeeds[index];

    try {
      await _cameraChannel.invokeMethod('setShutter', seconds);

      if (!mounted) {
        return;
      }

      setState(() {
        _shutterIndex = index;
      });
    } on PlatformException catch (error) {
      debugPrint('셔터 변경 실패: ${error.message}');
    }
  }

  Future<void> _setFocus(double value) async {
    try {
      await _cameraChannel.invokeMethod('setFocus', value);

      if (!mounted) {
        return;
      }

      setState(() {
        _focus = value;
      });
    } on PlatformException catch (error) {
      debugPrint('초점 변경 실패: ${error.message}');
    }
  }

  Future<void> _setZoom(double value) async {
    try {
      await _cameraChannel.invokeMethod('setZoom', value);

      if (!mounted) {
        return;
      }

      setState(() {
        _zoom = value;
      });
    } on PlatformException catch (error) {
      debugPrint('줌 변경 실패: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const UiKitView(viewType: 'ios-camera-preview'),

            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _topButton(icon: Icons.flash_off, onPressed: () {}),
                  const Text(
                    'MANUAL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  _topButton(icon: Icons.settings, onPressed: () {}),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ValueItem(title: 'ISO', value: _iso.round().toString()),
                        ValueItem(title: 'SHUTTER', value: _shutterLabel),
                        ValueItem(
                          title: 'EV',
                          value:
                              '${_ev >= 0 ? '+' : ''}'
                              '${_ev.toStringAsFixed(1)}',
                        ),
                        ValueItem(
                          title: 'FOCUS',
                          value: _focus.toStringAsFixed(2),
                        ),
                        ValueItem(
                          title: 'LENS',
                          value: '${_zoom.toStringAsFixed(1)}×',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildISOControl(),
                  _buildEVControl(),
                  _buildShutterControl(),
                  _buildFocusControl(),
                  _buildZoomControl(),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _capturePhoto,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing ? Colors.grey : Colors.white,
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                      child: _isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'PHOTO',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildISOControl() {
    return _buildSlider(
      label: 'ISO',
      value: _iso,
      min: 32,
      max: 3200,
      divisions: 99,
      displayValue: _iso.round().toString(),
      onChanged: _setISO,
    );
  }

  Widget _buildEVControl() {
    return _buildSlider(
      label: 'EV',
      value: _ev,
      min: -2,
      max: 2,
      divisions: 40,
      displayValue: '${_ev >= 0 ? '+' : ''}${_ev.toStringAsFixed(1)}',
      onChanged: _setEV,
    );
  }

  Widget _buildShutterControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const SizedBox(
            width: 50,
            child: Text(
              'SPEED',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Slider(
              value: _shutterIndex.toDouble(),
              min: 0,
              max: (_shutterSpeeds.length - 1).toDouble(),
              divisions: _shutterSpeeds.length - 1,
              onChanged: (value) {
                _setShutter(value.round());
              },
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(_shutterLabel, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusControl() {
    return _buildSlider(
      label: 'FOCUS',
      value: _focus,
      min: 0,
      max: 1,
      divisions: 100,
      displayValue: _focus.toStringAsFixed(2),
      onChanged: _setFocus,
    );
  }

  Widget _buildZoomControl() {
    return _buildSlider(
      label: 'LENS',
      value: _zoom,
      min: 1,
      max: 10,
      divisions: 90,
      displayValue: '${_zoom.toStringAsFixed(1)}×',
      onChanged: _setZoom,
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(displayValue, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _topButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.white,
        onPressed: onPressed,
      ),
    );
  }
}

class ValueItem extends StatelessWidget {
  final String title;
  final String value;

  const ValueItem({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white60,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
