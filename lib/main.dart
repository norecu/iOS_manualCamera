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
  static const MethodChannel cameraChannel = MethodChannel('ios-camera');

  bool isCapturing = false;
  double iso = 100;

  Future<void> capturePhoto() async {
    if (isCapturing) {
      return;
    }

    setState(() {
      isCapturing = true;
    });

    try {
      await cameraChannel.invokeMethod('capturePhoto');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진이 저장되었습니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 촬영 실패: ${e.message ?? '알 수 없는 오류'}')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('사진 촬영 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isCapturing = false;
        });
      }
    }
  }

  Future<void> setISO(double value) async {
    try {
      await cameraChannel.invokeMethod('setISO', value);

      if (!mounted) {
        return;
      }

      setState(() {
        iso = value;
      });
    } on PlatformException catch (e) {
      debugPrint('ISO 변경 실패: ${e.message}');
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
            // iOS 카메라 미리보기
            const UiKitView(viewType: 'ios-camera-preview'),

            // 상단 UI
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  topButton(icon: Icons.flash_off, onPressed: () {}),
                  const Text(
                    'MANUAL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  topButton(icon: Icons.settings, onPressed: () {}),
                ],
              ),
            ),

            // 하단 UI
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 현재 설정값
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
                        ValueItem(title: 'ISO', value: iso.round().toString()),
                        const ValueItem(title: 'SHUTTER', value: 'AUTO'),
                        const ValueItem(title: 'EV', value: '0.0'),
                        const ValueItem(title: 'FOCUS', value: 'AUTO'),
                        const ValueItem(title: 'LENS', value: '1×'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ISO 슬라이더
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 32,
                          child: Text(
                            'ISO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: iso,
                            min: 32,
                            max: 3200,
                            divisions: 99,
                            onChanged: setISO,
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            iso.round().toString(),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 촬영 버튼
                  GestureDetector(
                    onTap: capturePhoto,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCapturing ? Colors.grey : Colors.white,
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                      child: isCapturing
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

  Widget topButton({required IconData icon, required VoidCallback onPressed}) {
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
