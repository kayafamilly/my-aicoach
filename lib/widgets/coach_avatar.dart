import 'package:flutter/material.dart';

class CoachAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? avatarUrl;

  const CoachAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.avatarUrl,
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // indigo → violet
    [Color(0xFF3B82F6), Color(0xFF06B6D4)], // blue → cyan
    [Color(0xFF10B981), Color(0xFF34D399)], // emerald → green
    [Color(0xFFF59E0B), Color(0xFFF97316)], // amber → orange
    [Color(0xFFEF4444), Color(0xFFF43F5E)], // red → rose
    [Color(0xFF8B5CF6), Color(0xFFEC4899)], // violet → pink
    [Color(0xFF14B8A6), Color(0xFF3B82F6)], // teal → blue
    [Color(0xFFE11D48), Color(0xFFF59E0B)], // rose → amber
    [Color(0xFF7C3AED), Color(0xFF2563EB)], // purple → blue
    [Color(0xFF059669), Color(0xFF0891B2)], // emerald → cyan
  ];

  List<Color> _getGradient() {
    final index = name.hashCode.abs() % _gradients.length;
    return _gradients[index];
  }

  String _getInitials() {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return ClipOval(
        child: Image.asset(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildGradientAvatar(),
        ),
      );
    }
    return _buildGradientAvatar();
  }

  Widget _buildGradientAvatar() {
    final gradient = _getGradient();
    final initials = _getInitials();
    final fontSize = size * 0.38;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
