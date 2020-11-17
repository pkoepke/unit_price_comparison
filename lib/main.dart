import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Price Comparison',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Expanded(
                child: Text('Item 1', textAlign: TextAlign.center),
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: 'Price \$'),
              )),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: 'Units'),
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
              )),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: 'Item name'),
              )),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: 'Unit name'),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}
