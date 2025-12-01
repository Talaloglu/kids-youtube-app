import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String nameArabic;
  final String description;
  final IconData icon;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Predefined adult content categories
final List<Category> adultCategories = [
  Category(
    id: 'drama',
    name: 'Drama',
    nameArabic: 'دراما',
    description: 'مسلسلات درامية',
    icon: Icons.theater_comedy,
    color: const Color(0xFFE50914), // Netflix Red
  ),
  Category(
    id: 'comedy',
    name: 'Comedy',
    nameArabic: 'كوميديا',
    description: 'كوميديا وترفيه',
    icon: Icons.sentiment_very_satisfied,
    color: const Color(0xFFF59E0B), // Amber
  ),
  Category(
    id: 'action',
    name: 'Action',
    nameArabic: 'أكشن',
    description: 'أكشن وإثارة',
    icon: Icons.flash_on,
    color: const Color(0xFFEF4444), // Red
  ),
  Category(
    id: 'romance',
    name: 'Romance',
    nameArabic: 'رومانسية',
    description: 'رومانسية',
    icon: Icons.favorite,
    color: const Color(0xFFEC4899), // Pink
  ),
  Category(
    id: 'thriller',
    name: 'Thriller',
    nameArabic: 'إثارة',
    description: 'إثارة وتشويق',
    icon: Icons.psychology,
    color: const Color(0xFF8B5CF6), // Purple
  ),
  Category(
    id: 'documentary',
    name: 'Documentary',
    nameArabic: 'وثائقي',
    description: 'أفلام وثائقية',
    icon: Icons.movie_filter,
    color: const Color(0xFF10B981), // Green
  ),
  Category(
    id: 'talk_shows',
    name: 'Talk Shows',
    nameArabic: 'برامج حوارية',
    description: 'برامج حوارية',
    icon: Icons.mic,
    color: const Color(0xFF3B82F6), // Blue
  ),
  Category(
    id: 'news',
    name: 'News',
    nameArabic: 'أخبار',
    description: 'أخبار ومعلومات',
    icon: Icons.newspaper,
    color: const Color(0xFF6366F1), // Indigo
  ),
  Category(
    id: 'sports',
    name: 'Sports',
    nameArabic: 'رياضة',
    description: 'رياضة ونشاطات',
    icon: Icons.sports_soccer,
    color: const Color(0xFF14B8A6), // Teal
  ),
  Category(
    id: 'music',
    name: 'Music',
    nameArabic: 'موسيقى',
    description: 'موسيقى وأغاني',
    icon: Icons.music_note,
    color: const Color(0xFFB91C1C), // Dark Red
  ),
];
