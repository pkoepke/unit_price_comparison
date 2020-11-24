// TODO improve next button behavior
// TODO make launcher icons round
// TODO improve green highlighting color
// TODO shrink APK size

import 'package:flutter/material.dart'; // Material design
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:flutter/rendering.dart'; // For debugPaintSizeEnabled
import 'dart:async'; // For Timer class.
import 'package:shared_preferences/shared_preferences.dart';

// String testOutput = ""; // just for testing

const animationDuration = 500;

/// Construct a color from a hex code string, of the format #RRGGBB.
Color hexToColor(String code) {
  return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

final dukeBlue = hexToColor("#001A57");
final cardBackground = hexToColor("#424242");

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

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: dukeBlueMaterialColorSwatch,
  scaffoldBackgroundColor: Colors.black,
  backgroundColor: Colors.grey[900],
);

TextSelectionThemeData darkThemeTextSelection = TextSelectionThemeData(
  cursorColor: Colors.white,
  selectionColor: Colors.grey[700],
  selectionHandleColor: Colors.white,
);

TextSelectionThemeData lightThemeTextSelection = TextSelectionThemeData();

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: dukeBlueMaterialColorSwatch,
  backgroundColor: Colors.white,
);

ThemeData currentTheme = darkTheme;

void saveThemePref(String theme) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString("theme", theme);
}

//void main() => runApp(MyApp());
void main() {
  //debugPaintSizeEnabled = true;
  runApp(MyApp());
}

//Original stateless root
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Price Comparison',
      theme: currentTheme,
      home: MyHomePage(title: 'Unit Price Comparison'),
    );
  }
}

// Trying to add state to the root widget so we can switch the app's theme, but it threw an error like the widget wasn't in the tree:
// >setState() called in constructor: _MyAppState#2268d(lifecycle state: created, no widget, not mounted)
// >This happens when you call setState() on a State object for a widget that hasn't been inserted into the widget tree yet. It is not necessary to call setState() in the constructor, since the state is already assumed to be dirty when it is initially created.
/*class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Price Comparison',
      theme: currentTheme,
      home: MyHomePage(title: 'Unit Price Comparison'),
    );
  }

  void swapTheme() {
    setState(() {
      if (currentTheme == darkTheme)
        currentTheme = lightTheme;
      else
        currentTheme = darkTheme;
    });
  }
}*/

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _cardCounter =
      5; // Starting number of cards. Counts from 1 up so it matches the number shown on the cards, is not an array index which would start at 0.
  bool _secondRowOpaque = false;
  bool _showSecondRow = false;
  String _themePref = "dark";
  List<double> _allPrices = [];
  List<double> _allUnits = [];
  List<double> _allQtys = [];
  List<double> _allPricePerUnits = [];
  List<TextEditingController> _priceControllers = [];
  List<TextEditingController> _unitControllers = [];
  List<TextEditingController> _qtyControllers = [];
  //List<Widget> _cardList = [SizedBox(height: 100.0)];

  @override
  void initState() {
    super.initState();
    // When the widget is created, get the last-used theme from preferences.
    SharedPreferences.getInstance().then((prefs) {
      _themePref = prefs.getString("theme") ??
          getSystemTheme(); // If null then there's no recorded preference, so it's probably first launch. In that case match the system theme.
      setState(() {
        if (_themePref == "dark") {
          currentTheme = darkTheme;
        } else {
          currentTheme = lightTheme;
        }
        saveThemePref(_themePref);
        // Set lists to initial length so assignment below doesn't throw errors.
        _allPrices = List<double>(_cardCounter);
        _allUnits = List<double>(_cardCounter);
        _allQtys = List<double>(_cardCounter);
        _allPricePerUnits = List<double>(_cardCounter);
        _priceControllers = buildTextEditingControllers(_cardCounter);
        _unitControllers = buildTextEditingControllers(_cardCounter);
        _qtyControllers = buildTextEditingControllers(_cardCounter);
        //_cardList = buildCardList(_cardCounter);
      });
    });
  }

  List<Widget> buildCardList(_cardCounter) {
    List<Widget> cardList = [];
    //cardList.add(Text(testOutput)); // just for testing.
    for (int i = 0; i < _cardCounter; i++) {
      cardList.add(makeItemCard(context, i, _showSecondRow, _secondRowOpaque));
    }
    cardList.add(SizedBox(height: 80.0));
    return cardList;
  }

  void addCard() {
    setState(() {
      _cardCounter++;
      _allPrices = List<double>(_cardCounter);
      _allUnits = List<double>(_cardCounter);
      _allQtys = List<double>(_cardCounter);
      _allPricePerUnits = List<double>(_cardCounter);
      _priceControllers.add(new TextEditingController());
      _unitControllers.add(new TextEditingController());
      _qtyControllers.add(new TextEditingController());
      doCalculations();
    });
  }

  void removeCard() {
    if (_cardCounter > 2) {
      setState(() {
        _cardCounter--;
        _allPrices = List<double>(_cardCounter);
        _allUnits = List<double>(_cardCounter);
        _allQtys = List<double>(_cardCounter);
        _allPricePerUnits = List<double>(_cardCounter);
        _priceControllers.removeLast();
        _unitControllers.removeLast();
        _qtyControllers.removeLast();
        doCalculations();
      });
    }
  }

  void showHideSecondRow() {
    // Delay hiding the second row if it's shown to allow the fade out to finish.
    if (_showSecondRow) {
      setState(() {
        _secondRowOpaque = !_secondRowOpaque;
      });
      Timer(
          Duration(milliseconds: animationDuration),
          () => setState(() {
                _showSecondRow =
                    _secondRowOpaque; // To avoid race conditions when the button is pushed repeatedly, make sure the values are synced up.
              }));
    } else {
      setState(() {
        _showSecondRow = !_showSecondRow;
      });
      setState(() {
        _secondRowOpaque = !_secondRowOpaque;
      });
    }
  }

  void swapTheme() {
    setState(() {
      if (currentTheme == darkTheme) {
        currentTheme = lightTheme;
        saveThemePref("light");
      } else {
        currentTheme = darkTheme;
        saveThemePref("dark");
      }
    });
  }

  String getSystemTheme() {
    Brightness systemTheme = MediaQuery.of(context).platformBrightness;
    if (systemTheme == Brightness.dark)
      return "dark";
    else
      return "light";
  }

  void clearAll() {
    setState(() {
      _priceControllers.forEach((element) {
        element.clear();
      });
      _unitControllers.forEach((element) {
        element.clear();
      });
      _qtyControllers.forEach((element) {
        element.clear();
      });
      _allPricePerUnits.forEach((element) {
        element = null;
      });
    });
  }

  List<TextEditingController> buildTextEditingControllers(int cardNum) {
    List<TextEditingController> textEditingControllerList = [];
    for (int i = 0; i < _cardCounter; i++) {
      textEditingControllerList.add(new TextEditingController());
    }
    return textEditingControllerList;
  }

  @override
  void dispose() {
    _priceControllers.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  TextEditingController getControllerSafely(
      List<TextEditingController> controllerList, int cardNum) {
    if (controllerList.asMap().containsKey(cardNum))
      return controllerList[cardNum];
    else
      return null;
  }

  void doCalculations() {
    setState(() {
      for (int i = 0; i < _cardCounter; i++) {
        if (_priceControllers[i].text != null &&
            _priceControllers[i].text != '')
          _allPrices[i] = double.parse(_priceControllers[i].text);
        else
          _allPrices[i] = null;
        if (_unitControllers[i].text != null && _unitControllers[i].text != '')
          _allUnits[i] = double.parse(_unitControllers[i].text);
        else
          _allUnits[i] = null;
        if (_qtyControllers[i].text != null && _qtyControllers[i].text != '')
          _allQtys[i] = double.parse(_qtyControllers[i].text);
        else
          _allQtys[i] = 1.0;
        if ((_allPrices[i] is double) &&
            (_allUnits[i] is double) &&
            (_allQtys[i] is double)) {
          _allPricePerUnits[i] = (_allPrices[i] / (_allUnits[i] * _allQtys[i]));
        } else {
          _allPricePerUnits[i] = null;
        }
      }
      // just for testing
      /*print(_allPrices[0]);
      print(_allUnits[0]);
      print(_allQtys[0]);
      print(_allPricePerUnits[0]);
      print(_priceControllers[0].text);
      testOutput = _priceControllers[0].text;*/
      //testOutput = "testOutput";
    });
  }

  String showPricePerUnit(int i) {
    if (_allPricePerUnits.asMap().containsKey(i) &&
        _allPricePerUnits[i] != null)
      return _allPricePerUnits[i].toStringAsFixed(3);
    else
      return 'price/units';
  }

  bool isLowestPrice(int cardNum) {
    if (_allPricePerUnits.isEmpty) return false;
    double lowest = 9999999999999999.9;
    _allPricePerUnits.forEach((element) {
      if ((element != null) && element < lowest) lowest = element;
    });
    if (_allPricePerUnits[cardNum] == lowest) return true;
    return false;
  }

  // Originally I declared this function outside of the _MyHomePageState class and it worked fine.
  Widget makeItemCard(BuildContext context, int cardNum, bool showSecondRow,
      bool secondRowOpaque) {
    int showCardNum = cardNum +
        1; // cardNum is an array index so starts at 0. showCardNum is what we display to the user so it starts at 1 and is always 1 more than cardNum.
    return Card(
      color: currentTheme.backgroundColor,
      //color: Colors.grey[900],
      child: Container(
        margin: EdgeInsets.only(left: 2.0, right: 2.0, top: 2.0, bottom: 7.0),
        child: Column(
          children: [
            Container(
              height: 50,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: <
                      Widget>[
                Expanded(
                  child: Text('Item $showCardNum', textAlign: TextAlign.center),
                ),
                Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.only(left: 2.0, right: 2.0),
                      child: TextSelectionTheme(
                        data: (currentTheme == darkTheme)
                            ? darkThemeTextSelection
                            : lightThemeTextSelection,
                        child: TextField(
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(hintText: 'Price \$'),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*'))
                          ],
                          textInputAction: TextInputAction.next,
                          controller:
                              getControllerSafely(_priceControllers, cardNum),
                          onChanged: (text) {
                            doCalculations();
                          },
                          //onChanged: ,
                        ),
                      ),
                    )),
                Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.only(left: 2.0, right: 2.0),
                      child: TextSelectionTheme(
                        data: (currentTheme == darkTheme)
                            ? darkThemeTextSelection
                            : lightThemeTextSelection,
                        child: TextField(
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(hintText: 'Units'),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*'))
                          ],
                          textInputAction: TextInputAction.next,
                          controller:
                              getControllerSafely(_unitControllers, cardNum),
                          onChanged: (text) {
                            doCalculations();
                          },
                        ),
                      ),
                    )),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
                    decoration: new BoxDecoration(
                        color: isLowestPrice(cardNum)
                            ? Colors.green
                            : currentTheme.backgroundColor),
                    child: Text(
                      showPricePerUnit(cardNum),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          backgroundColor: isLowestPrice(cardNum)
                              ? Colors.green
                              : currentTheme.backgroundColor),
                    ),
                  ),
                ),
              ]),
            ),
            Visibility(
              visible: showSecondRow,
              maintainState: true,
              child: AnimatedOpacity(
                opacity: secondRowOpaque ? 1.0 : 0.0,
                duration: Duration(milliseconds: animationDuration),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(left: 3.0, right: 3.0),
                        child: TextSelectionTheme(
                          data: (currentTheme == darkTheme)
                              ? darkThemeTextSelection
                              : lightThemeTextSelection,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'Qty'),
                            keyboardType: TextInputType.numberWithOptions(),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d*'))
                            ],
                            textInputAction: TextInputAction.next,
                            controller:
                                getControllerSafely(_qtyControllers, cardNum),
                            onChanged: (text) {
                              doCalculations();
                            },
                          ),
                        ),
                      )),
                      Expanded(
                          child: Container(
                        margin: const EdgeInsets.only(left: 3.0, right: 3.0),
                        child: TextSelectionTheme(
                          data: (currentTheme == darkTheme)
                              ? darkThemeTextSelection
                              : lightThemeTextSelection,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'Item name'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      )),
                      Expanded(
                          child: Container(
                        margin: const EdgeInsets.only(left: 3.0, right: 3.0),
                        child: TextSelectionTheme(
                          data: (currentTheme == darkTheme)
                              ? darkThemeTextSelection
                              : lightThemeTextSelection,
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'Unit name'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      )),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //matchSystemTheme(); Won't run on every build, instead will default to dark theme and respect button pushes.
    return Theme(
      data: currentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: dukeBlue,
          actions: [
            IconButton(
              icon: Icon(Icons.invert_colors_off),
              onPressed: () {
                //_MyAppState().swapTheme(); // Requires stateful root widget, see 'class MyApp extends StatefulWidget'
                swapTheme();
              },
            ),
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                clearAll();
              },
            ),
            IconButton(
              icon: Icon(Icons.unfold_more), //unfold_less will be the opposite
              onPressed: () {
                showHideSecondRow();
              },
            ),
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
      ),
    );
  }
}
