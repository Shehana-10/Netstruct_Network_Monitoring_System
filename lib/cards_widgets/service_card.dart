import 'package:flutter/material.dart';

class ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> benefits;

  const ServiceCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.benefits,
  }) : super(key: key);

  @override
  _ServiceCardState createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final double baseWidth = isMobile ? screenWidth / 1.1 : 250;
    final double cardWidth = _expanded ? baseWidth + 20 : baseWidth;

    // Theme-based styling
    final Color backgroundColor =
        isDarkMode
            ? const Color(0xFF161B22)
            : const Color.fromARGB(255, 210, 232, 244);

    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color descriptionColor =
        isDarkMode ? Colors.white70 : Colors.grey[800]!;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: _expanded ? 16 : 8,
            offset: Offset(0, _expanded ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: TextStyle(fontSize: 14, color: descriptionColor),
            ),
            const SizedBox(height: 8),
            ...widget.benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Desktop: Use hover
    if (!isMobile) {
      return MouseRegion(
        onEnter: (_) => setState(() => _expanded = true),
        onExit: (_) => setState(() => _expanded = false),
        child: card,
      );
    }

    // Mobile: Tap to expand/collapse
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: card,
    );
  }
}
