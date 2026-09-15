import 'package:flutter/material.dart';

import '../../widgets/brand_logo.dart';
import '../../widgets/google_logo.dart';

const _deepBlue = Color(0xFF1976D2);
const _ink = Color(0xFF17324D);
const _mutedInk = Color(0xFF6F8192);

class LoginView extends StatelessWidget {
  const LoginView({
    required this.onGoogleSignIn,
    required this.onContinueAsGuest,
    super.key,
  });

  final VoidCallback onGoogleSignIn;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 34, 0, 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: BrandLogo(key: Key('brand_logo')),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'TO DO LIST',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: _ink,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 34,
                                      letterSpacing: 2,
                                      height: 1.15,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sắp xếp công việc gọn gàng, hoàn thành mục tiêu mỗi ngày.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: _mutedInk, height: 1.5),
                              ),
                              const SizedBox(height: 38),
                              _GoogleButton(onPressed: onGoogleSignIn),
                              const SizedBox(height: 14),
                              OutlinedButton(
                                key: const Key('continue_as_guest_button'),
                                onPressed: onContinueAsGuest,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _deepBlue,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.76,
                                  ),
                                  minimumSize: const Size.fromHeight(56),
                                  side: const BorderSide(
                                    color: Color(0xFFB7D9F8),
                                    width: 1.3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('Tiếp tục không đăng nhập'),
                              ),
                              const SizedBox(height: 30),
                              const _StorageNotice(),
                              const SizedBox(height: 30),
                              Text(
                                'Bằng việc tiếp tục, bạn đồng ý với Điều khoản sử dụng và Chính sách quyền riêng tư.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF92A3B3),
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDFF2FF), Color(0xFFF8FCFF), Colors.white],
          stops: [0, 0.48, 1],
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 145,
          width: double.infinity,
          child: CustomPaint(painter: _BottomWavePainter()),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const Key('google_sign_in_button'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        elevation: 4,
        shadowColor: _deepBlue.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GoogleLogo(),
          SizedBox(width: 12),
          Text('Tiếp tục với Google'),
        ],
      ),
    );
  }
}

class _StorageNotice extends StatelessWidget {
  const _StorageNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        border: Border.all(color: const Color(0xFFCFE8FC)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1976D2),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F4FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: _deepBlue,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dữ liệu của bạn',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'Đăng nhập để đồng bộ nhiều thiết bị. Chế độ khách chỉ lưu dữ liệu trên máy này.',
                  style: TextStyle(
                    color: _mutedInk,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomWavePainter extends CustomPainter {
  const _BottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final backWave = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.15,
        size.width * 0.55,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.86,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backWave, Paint()..color = const Color(0xFFCDEBFF));

    final frontWave = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.47,
        size.width * 0.68,
        size.height * 0.76,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.92,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontWave, Paint()..color = const Color(0xFFEAF7FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
