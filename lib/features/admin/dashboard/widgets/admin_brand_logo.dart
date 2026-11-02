import 'package:flutter/material.dart';

/// The "S" bolt logo (same crop as the login / splash screens).
/// lib/assets/images/imglo.jpeg also contains the company text, so only the
/// icon part is cut out.
class AdminBrandLogo extends StatelessWidget {
  final double size;
  const AdminBrandLogo({super.key, this.size = 40});

  static const String _asset = 'lib/assets/images/imglo.jpeg';
  static const Color _orange = Color(0xFFE8622C);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: ClipRect(
          child: Align(
            // window = 50% of the image, centred on the S icon
            alignment: const Alignment(-0.2, -0.22),
            widthFactor: 0.5,
            heightFactor: 0.5,
            child: Image.asset(
              _asset,
              width: 1000,
              height: 1000,
              fit: BoxFit.cover,
              errorBuilder: (_, error, __) => const SizedBox(
                width: 1000,
                height: 1000,
                child: Icon(Icons.bolt_rounded, color: _orange, size: 500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}