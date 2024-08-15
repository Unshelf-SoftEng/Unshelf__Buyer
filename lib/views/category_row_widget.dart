import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unshelf_buyer/views/category_view.dart';

class CategoryIconsRow extends StatelessWidget {
  final List<CategoryItem> categories = [
    CategoryItem('Offers', 'assets/images/category_offers.svg', 'offers'),
    CategoryItem('Grocery', 'assets/images/category_grocery.svg', 'grocery'),
    CategoryItem('Fruits', 'assets/images/category_fruits.svg', 'fruits'),
    CategoryItem('Veggies', 'assets/images/category_vegetables.svg', 'veggies'),
    CategoryItem('Baked', 'assets/images/category_baked.svg', 'baked'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((category) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryProductsPage(category: category),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2.0),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(category.iconPath),
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  category.name,
                  style: TextStyle(fontSize: 14.0, color: Colors.green),
                ),
              ],
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
