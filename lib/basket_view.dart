import 'package:flutter/material.dart';

class BasketView extends StatefulWidget {
  @override
  _BasketViewState createState() => _BasketViewState();
}

class _BasketViewState extends State<BasketView> {
  // Populate list with items taken from Firebase
  List<Item> items = [
    Item(
      name: 'Test Item',
      price: 120,
      quantity: 1,
      imageUrl: 'https://via.placeholder.com/100',
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Basket'),
        backgroundColor: const Color(0xff6a994e), // HEX: 6a994e
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: const Color(0xffa7c957), // HEX: a7c957
              height: 4.0,
            )),
      ),
      body: ListView(
        children: items.map((item) => buildItemCard(item)).toList(),
      ),
      bottomNavigationBar: buildTotalCheckout(),
    );
  }

  Widget buildItemCard(Item item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                    value: item.isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        item.isSelected = value!;
                      });
                    }),
                Image.network(
                  item.imageUrl,
                  width: 50,
                  height: 50,
                ),
                SizedBox(width: 10),
                Text(item.name),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Variant 1'),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (item.quantity > 0) item.quantity--;
                        });
                      },
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          item.quantity++;
                        });
                      },
                    ),
                  ],
                ),
                Text('₱${item.price * item.quantity}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTotalCheckout() {
    int total = items.fold(0, (sum, item) => sum + (item.price * item.quantity));

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total: ₱$total'),
            ElevatedButton(
              onPressed: () {
                // Handle checkout
              },
              child: Text('CHECKOUT'),
            ),
          ],
        ),
      ),
    );
  }
}

class Item {
  String name;
  int price;
  int quantity;
  String imageUrl;
  bool isSelected;

  Item({
    required this.name,
    this.price = 0,
    this.quantity = 1,
    required this.imageUrl,
    this.isSelected = false,
  });
}
