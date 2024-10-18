import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unshelf_buyer/views/category_view.dart';

class CategoryIconsRow extends StatefulWidget {
  @override
  _CategoryIconsRowState createState() => _CategoryIconsRowState();
}

class _CategoryIconsRowState extends State<CategoryIconsRow> {
  int _pressedIndex = -1; // Track which button is pressed

  // Removed "Offers" category
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                borderRadius: BorderRadius.circular(24.0), // Rounded button
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  SvgPicture.asset(category.iconPath, height: 20.0, width: 20.0),
                  const SizedBox(width: 6.0),
                  Text(
                    category.name,
                    style: TextStyle(fontSize: 12.0, color: _pressedIndex == index ? Colors.white : const Color(0xFF6E9E57)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
