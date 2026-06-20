import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// This file maps category NAME keywords to an Icon + Color
// When user types a category name, we search this list for
// any matching keyword and return the best-fit icon
// ─────────────────────────────────────────────────────────────

class CategoryIconHelper {

  // Each entry: list of keywords → icon + color
  // We check keywords using "contains" so partial matches work too
  // Example: "Vegetables" matches keyword "vegetable"
  static final List<_CategoryRule> _rules = [
    _CategoryRule(['food', 'lunch', 'dinner', 'breakfast', 'meal', 'restaurant', 'eat'],
        Icons.restaurant_rounded, Colors.orange),
    _CategoryRule(['vegetable', 'veggies', 'sabzi'],
        Icons.eco_rounded, Colors.green),
    _CategoryRule(['fruit', 'fruits'],
        Icons.apple_rounded, Colors.red),
    _CategoryRule(['milk', 'grocery', 'groceries', 'dairy'],
        Icons.local_grocery_store_rounded, Colors.teal),
    _CategoryRule(['transport', 'fuel', 'petrol', 'diesel', 'car', 'bike', 'uber', 'taxi', 'fare'],
        Icons.directions_car_rounded, Colors.blue),
    _CategoryRule(['bus', 'travel', 'flight', 'trip', 'ticket'],
        Icons.flight_rounded, Colors.indigo),
    _CategoryRule(['shopping', 'clothes', 'clothing', 'shirt', 'dress'],
        Icons.shopping_bag_rounded, Colors.pink),
    _CategoryRule(['salary', 'income', 'pocket money', 'wage', 'pay'],
        Icons.payments_rounded, Colors.green),
    _CategoryRule(['bonus', 'gift', 'reward'],
        Icons.card_giftcard_rounded, Colors.purple),
    _CategoryRule(['rent', 'house', 'home'],
        Icons.home_rounded, Colors.brown),
    _CategoryRule(['electricity', 'bill', 'utility', 'gas', 'water bill'],
        Icons.bolt_rounded, Colors.amber),
    _CategoryRule(['medicine', 'doctor', 'hospital', 'health', 'medical'],
        Icons.medical_services_rounded, Colors.redAccent),
    _CategoryRule(['education', 'fee', 'fees', 'school', 'university', 'tuition', 'book', 'books'],
        Icons.school_rounded, Colors.deepPurple,),
    _CategoryRule(['internet', 'wifi', 'mobile', 'phone bill', 'recharge'],
        Icons.wifi_rounded, Colors.cyan),
    _CategoryRule(['entertainment', 'movie', 'netflix', 'game', 'games', 'fun'],
        Icons.movie_rounded, Colors.deepOrange),
    _CategoryRule(['gym', 'fitness', 'sports', 'exercise'],
        Icons.fitness_center_rounded, Colors.lightGreen),
    _CategoryRule(['pet', 'pets', 'dog', 'cat'],
        Icons.pets_rounded, Colors.brown),
    _CategoryRule(['donation', 'charity', 'zakat', 'sadqa'],
        Icons.volunteer_activism_rounded, Colors.pinkAccent),
    _CategoryRule(['saving', 'savings', 'investment'],
        Icons.savings_rounded, Colors.green),
    _CategoryRule(['repair', 'maintenance', 'fix'],
        Icons.build_rounded, Colors.grey),
  ];

  // Default icon used when no keyword matches
  static const IconData _defaultIcon = Icons.category_rounded;
  static const Color _defaultColor = Colors.deepPurple;

  // ── Get Icon for a category name ─────────────────────────
  static IconData getIcon(String categoryName) {
    final lower = categoryName.toLowerCase().trim();

    for (var rule in _rules) {
      for (var keyword in rule.keywords) {
        if (lower.contains(keyword)) {
          return rule.icon;
        }
      }
    }
    return _defaultIcon; // no match found
  }

  // ── Get Color for a category name ────────────────────────
  static Color getColor(String categoryName) {
    final lower = categoryName.toLowerCase().trim();

    for (var rule in _rules) {
      for (var keyword in rule.keywords) {
        if (lower.contains(keyword)) {
          return rule.color;
        }
      }
    }
    return _defaultColor; // no match found
  }
}

// Helper class to store one matching rule
class _CategoryRule {
  final List<String> keywords;
  final IconData icon;
  final Color color;

  _CategoryRule(this.keywords, this.icon, this.color);
}