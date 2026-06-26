import 'package:flutter/material.dart';

class OwnerColors {
  OwnerColors._();

  static const pink = Color(0xFFCB8490);
  static const pinkDark = Color(0xFFB8707C);
  static const pinkBg = Color(0xFFF5EAEC);
  static const pinkBorder = Color(0xFFF0DCE0);
  static const white = Colors.white;
  static const textDark = Color(0xFF2D1B20);
  static const textGrey = Color(0xFF7A5560);
  static const textMid = Color(0xFF5C3D45);
  static const gold = Color(0xFFD4AF37);
  static const goldBg = Color(0xFFFFF8E7);
  static const green = Color(0xFF4CAF50);
  static const greenBg = Color(0xFFE8F5E9);
  static const greenText = Color(0xFF2E7D32);
  static const blue = Color(0xFF5B8DEF);
  static const blueBg = Color(0xFFEEF3FF);
  static const blueIcon = Color(0xFF3B6FD4);
  static const red = Color(0xFFE53935);
  static const redBg = Color(0xFFFFEBEE);
  static const yellow = Color(0xFFF59E0B);
  static const yellowBg = Color(0xFFFFF8E1);

  static const grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, pinkDark],
  );

  static final shadow = [
    BoxShadow(
      color: pink.withOpacity(0.12),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];
}
