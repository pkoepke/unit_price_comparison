import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; // For debugPaintSizeEnabled

/// Construct a color from a hex code string, of the format #RRGGBB.
Color hexToColor(String code) {
  return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

final dukeBlue = hexToColor("#001A57");

// Create a MaterialColor swatch from a single color.
// From https://medium.com/@filipvk/creating-a-custom-color-swatch-in-flutter-554bcdcb27f3
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}

final dukeBlueMaterialColorSwatch = createMaterialColor(dukeBlue);

//void main() => runApp(MyApp());
void main() {
  //debugPaintSizeEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Price Comparison',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: dukeBlueMaterialColorSwatch, // Colors.blue,
      ),
      home: MyHomePage(title: 'Unit Price Comparison'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _cardCounter = 5; // Starting number of cards

  void addCard() {
    setState(() {
      _cardCounter++;
    });
  }

  void removeCard() {
    if (_cardCounter > 2) // Only remove if there are more than 2 cards
      setState(() {
        _cardCounter--;
      });
  }

  List<Widget> buildCardList(_cardCounter) {
    List<Widget> cardList = [];
    // Starts at 1 because there is no item zero.
    for (int i = 1; i <= _cardCounter; i++) {
      cardList.add(makeItemCard(i));
    }
    return cardList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: dukeBlue,
        actions: [
          IconButton(
            icon: Icon(Icons.invert_colors_off),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.unfold_more), //unfold_less will be the opposite
            onPressed: () {},
          ),
          /*IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {},
          ),*/
        ],
      ),
      body: ListView(children: buildCardList(_cardCounter)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          /*FloatingActionButton(
            onPressed: () {
              // Add your onPressed code here!
            },
            child: Icon(Icons.invert_colors_off),
            backgroundColor: dukeBlue,
          ),
          FloatingActionButton(
            onPressed: () {
              // Add your onPressed code here!
            },
            child: Icon(Icons.clear),
            backgroundColor: Colors.red,
          ),*/
          FloatingActionButton(
            onPressed: () {
              removeCard();
            },
            child: Icon(
              Icons.remove,
              color: Colors.white,
            ),
            backgroundColor: dukeBlue,
          ),
          FloatingActionButton(
            onPressed: () {
              addCard();
            },
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
            backgroundColor: dukeBlue,
          ),
        ],
      ),
    );
  }
}

Widget makeItemCard(int cardNum) {
  return Card(
    child: Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Expanded(
            child: Text('Item $cardNum', textAlign: TextAlign.center),
          ),
          Expanded(
              child: TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'Price \$'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
            ],
            textInputAction: TextInputAction.next,
          )),
          Expanded(
              child: TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'Units'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
            ],
            textInputAction: TextInputAction.next,
          )),
          Expanded(
            child: Text('price/units', textAlign: TextAlign.center),
          ),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Expanded(
              child: TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'Qty'),
            keyboardType: TextInputType.numberWithOptions(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
            ],
            textInputAction: TextInputAction.next,
          )),
          Expanded(
              child: TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'Item name'),
            textInputAction: TextInputAction.next,
          )),
          Expanded(
              child: TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'Unit name'),
            textInputAction: TextInputAction.next,
          )),
        ]),
      ],
    ),
  );
}
