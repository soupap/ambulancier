import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth < 700 ? 0.96 : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF101826),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFF4F7FA)),
              child: Column(
                children: [
                  Container(
                    height: 56 * scale,
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: const Color(0xFF1E5CE4),
                          size: 18 * scale,
                        ),
                        SizedBox(width: 10 * scale),
                        Text(
                          'PROFILE',
                          style: TextStyle(
                            color: const Color(0xFF1E5CE4),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            fontSize: 13 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(14 * scale),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30 * scale,
                                  backgroundColor: const Color(0xFFE7F0FF),
                                  child: Icon(
                                    Icons.account_circle,
                                    size: 40 * scale,
                                    color: const Color(0xFF1D6EDA),
                                  ),
                                ),
                                SizedBox(width: 12 * scale),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ambulance Driver',
                                        style: TextStyle(
                                          fontSize: 11 * scale,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 2 * scale),
                                      Text(
                                        'John Paramedic',
                                        style: TextStyle(
                                          fontSize: 19 * scale,
                                          color: const Color(0xFF222831),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 2 * scale),
                                      Text(
                                        'ID: AMB-2391',
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          color: const Color(0xFF637086),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12 * scale),
                          _InfoTile(
                            title: 'Vehicle',
                            value: 'Ambulance Unit A-17',
                            icon: Icons.local_hospital,
                            scale: scale,
                          ),
                          SizedBox(height: 10 * scale),
                          _InfoTile(
                            title: 'Shift',
                            value: '08:00 - 20:00',
                            icon: Icons.schedule,
                            scale: scale,
                          ),
                          SizedBox(height: 10 * scale),
                          _InfoTile(
                            title: 'Dispatch Zone',
                            value: 'Central District',
                            icon: Icons.map,
                            scale: scale,
                          ),
                          SizedBox(height: 6 * scale),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 66 * scale,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24 * scale,
                      vertical: 8 * scale,
                    ),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BottomIcon(
                          label: 'MISSIONS',
                          icon: Icons.assignment_outlined,
                          active: false,
                          scale: scale,
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        _BottomIcon(
                          label: 'MAP',
                          icon: Icons.map,
                          active: false,
                          scale: scale,
                          onTap: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                        ),
                        _BottomIcon(
                          label: 'PROFILE',
                          icon: Icons.person_outline,
                          active: true,
                          scale: scale,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.scale,
  });

  final String title;
  final String value;
  final IconData icon;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Row(
        children: [
          Container(
            width: 34 * scale,
            height: 34 * scale,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Icon(icon, size: 17 * scale, color: const Color(0xFF1D6EDA)),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    color: const Color(0xFF2A303A),
                    fontWeight: FontWeight.w800,
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

class _BottomIcon extends StatelessWidget {
  const _BottomIcon({
    required this.label,
    required this.icon,
    required this.active,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12 * scale),
      onTap: onTap,
      child: SizedBox(
        width: 74 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30 * scale,
              height: 30 * scale,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFE8F0FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Icon(
                icon,
                size: 17 * scale,
                color:
                    active ? const Color(0xFF2B60E0) : const Color(0xFF98A4B8),
              ),
            ),
            SizedBox(height: 1 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 9 * scale,
                fontWeight: FontWeight.w700,
                color:
                    active ? const Color(0xFF2B60E0) : const Color(0xFF98A4B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
