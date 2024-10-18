import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unshelf_buyer/views/category_view.dart';

class CategoryIconsRow extends StatefulWidget {
  @override
  _CategoryIconsRowState createState() => _CategoryIconsRowState();
}

class _CategoryIconsRowState extends State<CategoryIconsRow> {
  int _pressedIndex = -1; // Track which button is pressed

  final List<CategoryItem> categories = [
    CategoryItem('Grocery', 'assets/images/category_grocery.svg', 'Grocery'),
    CategoryItem('Fruits', 'assets/images/category_fruits.svg', 'Fruits'),
    CategoryItem('Veggies', 'assets/images/category_vegetables.svg', 'Vegetables'),
    CategoryItem('Baked', 'assets/images/category_baked.svg', 'Baked Goods'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enable horizontal scrolling
        child: Row(
          children: categories.asMap().entries.map((entry) {
            int index = entry.key;
            CategoryItem category = entry.value;

            return GestureDetector(
              onTapDown: (_) => setState(() => _pressedIndex = index), // Button pressed
              onTapUp: (_) => setState(() => _pressedIndex = -1), // Button released
              onTapCancel: () => setState(() => _pressedIndex = -1), // In case of cancellation
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryProductsPage(category: category),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _pressedIndex == index ? const Color(0xFF6E9E57) : Colors.transparent,
                  border: Border.all(color: const Color(0xFF6E9E57)),
                  borderRadius: BorderRadius.circular(20.0), // Adjusted button radius
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0), // Increased padding
                margin: const EdgeInsets.symmetric(horizontal: 6.0), // Slightly more margin between buttons
                child: Row(
                  children: [
                    SvgPicture.asset(category.iconPath, height: 18.0, width: 18.0), // Slightly larger icon
                    const SizedBox(width: 6.0), // Increased spacing between icon and text
                    Text(
                      category.name,
                      style: TextStyle(
                          fontSize: 11.0, // Slightly larger text
                          fontWeight: FontWeight.bold,
                          color: _pressedIndex == index ? Colors.white : const Color(0xFF6E9E57)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CategoryItem {
  final String name;
  final String iconPath;
  final String categoryKey;

  CategoryItem(this.name, this.iconPath, this.categoryKey);
}
