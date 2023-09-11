// todo: get next field button on iOS and tab button on Windows desktop working.
// TODO: deploy to Ubuntu snap store
// TODO: clean up Git repo, add new files as appropriate and remove files that shouldn't be committed.

import 'package:intl/intl.dart'; // for NumberFormat.simpleCurrency
import 'dart:async'; // For Timer class
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'dart:ui'; // For window.locale
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const initialCards = 6;
const animationDuration = 500;

/// Construct a color from a hex code string, of the format #RRGGBB.
Color hexToColor(String code) {
  return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

final Color dukeBlue = hexToColor('#001A57');
final Color cardBackground = hexToColor('#424242');
final Color greenHighlight = hexToColor('#17B468');
const double bodyFontSize = 18;
const double inputContentPadding = 12;

// Create a MaterialColor swatch from a single color.
// From https://medium.com/@filipvk/creating-a-custom-color-swatch-in-flutter-554bcdcb27f3
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

final dukeBlueMaterialColorSwatch = createMaterialColor(dukeBlue);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: dukeBlueMaterialColorSwatch,
  scaffoldBackgroundColor: Colors.black,
  backgroundColor: Colors.grey[900],
  textTheme: darkTextTheme,
  appBarTheme: AppBarTheme(
    color: dukeBlue,
  ),
);

TextTheme darkTextTheme = TextTheme(
  bodyText2: darkTextStyle,
);

TextStyle darkTextStyle = const TextStyle(
  color: Colors.white,
  fontSize: bodyFontSize,
  //height: 1,
);

TextSelectionThemeData darkThemeTextSelection = TextSelectionThemeData(
  cursorColor: Colors.white,
  selectionColor: Colors.grey[700],
  selectionHandleColor: Colors.white,
);

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: dukeBlueMaterialColorSwatch,
  backgroundColor: Colors.white,
  textTheme: lightTextTheme,
  scaffoldBackgroundColor: Colors.grey[200],
  appBarTheme: AppBarTheme(
    color: dukeBlue,
  ),
);

TextTheme lightTextTheme = TextTheme(
  bodyText2: lightTextStyle,
);

TextStyle lightTextStyle = const TextStyle(
  color: Colors.black,
  fontSize: bodyFontSize,
);

TextSelectionThemeData lightThemeTextSelection = const TextSelectionThemeData();

ThemeData currentTheme = darkTheme;
//TextStyle currentTextStyle = darkTextStyle;

void saveThemePref(String theme) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString("theme", theme);
}

void main() {
  //debugPaintSizeEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Price Comparison',
      theme: currentTheme,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Unit Price' /*'Unit Price Comparison'*/),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _cardCounter =
      initialCards; // Starting number of cards. Counts up from 1, not 0, so it matches the number shown on the cards.
  bool _secondRowOpaque = false;
  bool _showSecondRow = false;
  String _themePref = "dark";

  // Make empty Lists to hold values.
  List<double> _allPrices = [];
  List<double> _allUnits = [];
  List<double> _allQtys = [];
  List<double> _allPricePerUnits = [];
  List<String> _allItemNames = [];
  List<String> _allUnitNames = [];

  // Make controllers for text fields.
  List<TextEditingController> _priceControllers =
      List<TextEditingController>.generate(
          initialCards, (i) => TextEditingController());
  List<TextEditingController> _unitControllers =
      List<TextEditingController>.generate(
          initialCards, (i) => TextEditingController());
  List<TextEditingController> _qtyControllers =
      List<TextEditingController>.generate(
          initialCards, (i) => TextEditingController());
  List<TextEditingController> _itemNameControllers =
      List<TextEditingController>.generate(
          initialCards, (i) => TextEditingController());
  List<TextEditingController> _unitNameControllers =
      List<TextEditingController>.generate(
          initialCards, (i) => TextEditingController());

  // Make Lists to hold FocusNodes, which handle keyboard focus.
  final List<FocusNode> _priceFocusNodes =
      List<FocusNode>.generate(initialCards, (i) => FocusNode());
  final List<FocusNode> _unitFocusNodes =
      List<FocusNode>.generate(initialCards, (i) => FocusNode());
  final List<FocusNode> _qtyFocusNodes =
      List<FocusNode>.generate(initialCards, (i) => FocusNode());
  final List<FocusNode> _itemNameFocusNodes =
      List<FocusNode>.generate(initialCards, (i) => FocusNode());
  final List<FocusNode> _unitNameFocusNodes =
      List<FocusNode>.generate(initialCards, (i) => FocusNode());

  // Set a default locale and currency. Later the system's preferred locale and currency during initState();
  String currentLocale = "en_US";
  String currencySymbol = "\$"; // ?? '\$';*/

  @override
  void initState() {
    super.initState();

    // Try to get the platform locales and currency symbol. If this fails keep en_US and $ as defaults. Should't fail but Platform.localeName didn't work on web so who knows.
    try {
      //https://stackoverflow.com/a/62825776/3784441
      currentLocale = window.locale
          .toString(); // replaced Platform.localeName with window.locale since the latter works on all platforms including web.
      currencySymbol =
          NumberFormat.simpleCurrency(locale: currentLocale).currencySymbol;
    } catch (e) {
      currentLocale =
          "en_US"; // Doesn't do anything except avoid warnings about empty catch blocks.
    }

    // When the widget is created, get the last-used theme from preferences.
    SharedPreferences.getInstance().then((prefs) {
      _themePref = prefs.getString("theme") ??
          getSystemTheme(); // If null then there's no recorded preference, so it's probably first launch. In that case match the system theme.
      setState(() {
        _themePref == "dark"
            ? currentTheme = darkTheme
            : currentTheme = lightTheme;
        saveThemePref(_themePref);

        // Set lists of values and controllers to initial lengths so assigning values doesn't throw errors.
        makeValueLists();
        _priceControllers = List<TextEditingController>.generate(
            _cardCounter, (i) => TextEditingController());
        _unitControllers = List<TextEditingController>.generate(
            _cardCounter, (i) => TextEditingController());
        _qtyControllers = List<TextEditingController>.generate(
            _cardCounter, (i) => TextEditingController());
        _itemNameControllers = List<TextEditingController>.generate(
            _cardCounter, (i) => TextEditingController());
        _unitNameControllers = List<TextEditingController>.generate(
            _cardCounter, (i) => TextEditingController());
      });
    });
  }

  // Makes lists to hold values that will be used in calculations. All values are initialized to -1 since null is no longer allowed, and the app doesn't support negative numbers so -1 is effectively null.
  // We could just add and remove items from the list when a card is added or removed, but re-creating the lists means fewer lines of code and the performance impact is trivial.
  void makeValueLists() {
    _allPrices = List<double>.generate(_cardCounter, (_cardCounter) => -1,
        growable: true);
    _allUnits = List<double>.generate(_cardCounter, (_cardCounter) => -1,
        growable: true);
    _allQtys = List<double>.generate(_cardCounter, (_cardCounter) => -1,
        growable: true);
    _allPricePerUnits = List<double>.generate(
        _cardCounter, (_cardCounter) => -1,
        growable: true);
    _allItemNames = List<String>.generate(_cardCounter, (_cardCounter) => '',
        growable: true);
    _allUnitNames = List<String>.generate(_cardCounter, (_cardCounter) => '',
        growable: true);
  }

  // Add FocusNodes for new card
  void addFocusNodes() {
    _priceFocusNodes.add(FocusNode());
    _unitFocusNodes.add(FocusNode());
    _qtyFocusNodes.add(FocusNode());
    _itemNameFocusNodes.add(FocusNode());
    _unitNameFocusNodes.add(FocusNode());
  }

  // Remove FocusNodes for deleted card
  void removeFocusNodes() {
    _priceFocusNodes.removeLast();
    _unitFocusNodes.removeLast();
    _qtyFocusNodes.removeLast();
    _itemNameFocusNodes.removeLast();
    _unitNameFocusNodes.removeLast();
  }

  List<Widget> buildCardList(_cardCounter) {
    List<Widget> cardList = [];
    //cardList.add(Text(testOutput)); // just for testing.
    for (int i = 0; i < _cardCounter; i++) {
      cardList.add(makeItemCard(context, i, _showSecondRow, _secondRowOpaque));
    }
    /*cardList.add(SizedBox(height: 80.0));*/ // Only needed for floating action buttons, which were removed.
    return cardList;
  }

  void addCard() {
    setState(() {
      _cardCounter++;
      makeValueLists();
      _priceControllers.add(TextEditingController());
      _unitControllers.add(TextEditingController());
      _qtyControllers.add(TextEditingController());
      _itemNameControllers.add(TextEditingController());
      _unitNameControllers.add(TextEditingController());
      addFocusNodes();
      doCalculations(); // if this isn't run, price per unit fields are cleared.
    });
  }

  void removeCard() {
    if (_cardCounter > 2) {
      setState(() {
        _cardCounter--;
        makeValueLists();
        _priceControllers.removeLast();
        _unitControllers.removeLast();
        _qtyControllers.removeLast();
        _itemNameControllers.removeLast();
        _unitNameControllers.removeLast();
        removeFocusNodes();
        doCalculations(); // if this isn't run, price per unit fields are cleared.
      });
    }
  }

  void showHideSecondRow() {
    // If the second row is visible, delay hiding it to allow the fade out to finish.
    if (_showSecondRow) {
      setState(() {
        _secondRowOpaque = !_secondRowOpaque;
      });
      Timer(
          const Duration(milliseconds: animationDuration),
          () => setState(() {
                _showSecondRow =
                    _secondRowOpaque; // To avoid race conditions when the button is pushed repeatedly, make sure the values are synced up.
              }));
    } else {
      setState(() {
        _showSecondRow = !_showSecondRow;
      });
      Timer(
          const Duration(milliseconds: 10), // Sometimes the opacity changes before the second row is shown, which hides the fade-in. This ensures that the fade-in starts after the second row is visible.
              () => setState(() {  _secondRowOpaque = _showSecondRow; // To avoid race conditions when the button is pushed repeatedly, make sure the values are synced up.
          }));
    }
  }

  void swapTheme() {
    setState(() {
      if (currentTheme == darkTheme) {
        currentTheme = lightTheme;
        //currentTextStyle = lightTextStyle;
        saveThemePref("light");
      } else {
        currentTheme = darkTheme;
        //currentTextStyle = darkTextStyle;
        saveThemePref("dark");
      }
    });
  }

  String getSystemTheme() {
    Brightness systemTheme = MediaQuery.of(context).platformBrightness;
    if (systemTheme == Brightness.dark) {
      return "dark";
    } else {
      return "light";
    }
  }

  void clearAll() {
    setState(() {
      for (var e in _priceControllers) {
        e.clear();
      }
      for (var e in _unitControllers) {
        e.clear();
      }
      for (var e in _qtyControllers) {
        e.clear();
      }
      for (var e in _itemNameControllers) {
        e.clear();
      }
      for (var e in _unitNameControllers) {
        e.clear();
      }
      doCalculations(); // Simplest way to clear price per units output fields.
    });
  }

  List<TextEditingController> buildTextEditingControllers(int cardNum) {
    List<TextEditingController> textEditingControllerList = [];
    for (int i = 0; i < _cardCounter; i++) {
      textEditingControllerList.add(TextEditingController());
    }
    return textEditingControllerList;
  }

  // Mandatory to release memory.
  @override
  void dispose() {
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    for (var e in _priceFocusNodes) {
      e.dispose();
    }
    for (var e in _unitFocusNodes) {
      e.dispose();
    }
    for (var e in _qtyFocusNodes) {
      e.dispose();
    }
    for (var e in _itemNameFocusNodes) {
      e.dispose();
    }
    for (var e in _unitNameFocusNodes) {
      e.dispose();
    }
    super.dispose();
  }

  // TODO test removing this, as constructor improvements probably make it unnecessary.
  // Had problems with errors caused by list items not existing at initial load, so this prevents those "list index doesn't exist" errors.
  TextEditingController getControllerSafely(
      List<TextEditingController> controllerList, int cardNum) {
    if (controllerList.asMap().containsKey(cardNum)) {
      return controllerList[cardNum];
    } else {
      return TextEditingController(); // If the controller doesn't exist yet, return a useless placeholder to avoid errors until the useful ones are created.
    }
  }

  // TODO test removing this, as constructor improvements probably make it unnecessary.
  // Had problems with errors caused by list items not existing at initial load, so this prevents those "list index doesn't exist" errors.
  FocusNode getFocusNodeSafely(List<FocusNode> focusNodeList, int cardNum) {
    if (focusNodeList.asMap().containsKey(cardNum)) {
      return focusNodeList[cardNum];
    } else {
      return FocusNode(); // If the node doesn't exist yet, return a useless placeholder to avoid errors until the useful ones are created.
    }
  }

  // -1 replaces null to signal "ignore this card" when displaying price per unit.
  void doCalculations() {
    setState(() {
      for (int i = 0; i < _cardCounter; i++) {
        // Get values
        if (_priceControllers[i].text.isNotEmpty) {
          _allPrices[i] = double.parse(_priceControllers[i].text);
        } else {
          _allPrices[i] = -1;
        }
        if (_unitControllers[i].text.isNotEmpty) {
          _allUnits[i] = double.parse(_unitControllers[i].text);
        } else {
          _allUnits[i] = -1;
        }
        if (_qtyControllers[i].text.isNotEmpty) {
          _allQtys[i] = double.parse(_qtyControllers[i].text);
        } else {
          _allQtys[i] = 1.0;
        }
        if (_itemNameControllers[i].text.isNotEmpty) {
          _allItemNames[i] = _itemNameControllers[i].text;
        } else {
          _allItemNames[i] = '';
        }
        if (_unitNameControllers[i].text.isNotEmpty) {
          _allUnitNames[i] = _unitNameControllers[i].text;
        } else {
          _allUnitNames[i] = '';
        }

        // Do calculations
        if ((_allPrices[i] >= 0) && (_allUnits[i] >= 0) && (_allQtys[i] >= 0)) {
          _allPricePerUnits[i] = (_allPrices[i] / (_allUnits[i] * _allQtys[i]));
        } else {
          _allPricePerUnits[i] = -1;
        }
      }
    });
  }

  String showPricePerUnit(int i) {
    if (_allPricePerUnits.asMap().containsKey(i) && _allPricePerUnits[i] >= 0) {
      return NumberFormat.simpleCurrency(
        locale: currentLocale,
        decimalDigits: 3,
      ).format(
        _allPricePerUnits[i],
      );
    } else {
      return currencySymbol + '/units';
    }
  }

  /*TODO: make this run just once when doCalculations() runs and store the value, rather than running once per card.
     Current setup highlights multiple cards if they have the same value so probably use _allPricePerUnits.reduce(min) from dart:math and store that value. */
  bool isLowestPrice(int cardNum) {
    if (_allPricePerUnits.isEmpty) return false;
    double lowest = 9999999999999999.9;
    for (var element in _allPricePerUnits) {
      if ((element >= 0) && element < lowest) lowest = element;
    }
    if (_allPricePerUnits[cardNum] == lowest) {
      return true;
    } else {
      return false;
    }
  }

  Widget makeItemCard(BuildContext context, int cardNum, bool showSecondRow,
      bool secondRowOpaque) {
    int showCardNum = cardNum +
        1; // cardNum is an array index so starts at 0. showCardNum is what we display to the user so it starts at 1 and is always 1 more than cardNum.
    return Card(
      color: currentTheme.backgroundColor,
      child: Container(
        margin:
            const EdgeInsets.only(left: 2.0, right: 2.0, top: 2.0, bottom: 5.0),
        child: Column(
          children: [
            SizedBox(
              height: 36, // 50 was comfortable but meant fewer items on screen
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Item $showCardNum',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
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
                              decoration: InputDecoration(
                                  hintText: 'Price ' + currencySymbol,
                                  contentPadding: const EdgeInsets.only(
                                    bottom: inputContentPadding,
                                  )),
                              style: currentTheme.textTheme.bodyText2,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d*'))
                              ],
                              textInputAction: TextInputAction.next,
                              controller: getControllerSafely(
                                  _priceControllers, cardNum),
                              onChanged: (text) {
                                doCalculations();
                              },
                              focusNode:
                                  getFocusNodeSafely(_priceFocusNodes, cardNum),
                              /*onSubmitted: (String str) {
                            FocusScope.of(context).requestFocus(_unitFocusNodes[cardNum]);
                          },*/
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
                              decoration: const InputDecoration(
                                  hintText: 'Units',
                                  contentPadding: EdgeInsets.only(
                                    bottom: inputContentPadding,
                                  )),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: currentTheme.textTheme.bodyText2,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d*'))
                              ],
                              textInputAction: TextInputAction.next,
                              controller: getControllerSafely(
                                  _unitControllers, cardNum),
                              onChanged: (text) {
                                doCalculations();
                              },
                              focusNode: _unitFocusNodes[cardNum],
                              onSubmitted: (String str) {
                                // TODO instead of returning to the first field, make the textInputAction done or similar so the keyboard disappears.
                                if (_showSecondRow) {
                                  FocusScope.of(context)
                                      .requestFocus(_qtyFocusNodes[cardNum]);
                                } else {
                                  if (cardNum == _cardCounter - 1) {
                                    FocusScope.of(context)
                                        .requestFocus(_priceFocusNodes[0]);
                                  } else {
                                    FocusScope.of(context).requestFocus(
                                        _priceFocusNodes[cardNum + 1]);
                                  }
                                }
                              },
                              //focusNode: allFocusNodes[cardNum * 2 - 1],
                            ),
                          ),
                        )),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.only(top: 5.0, bottom: 3.0),
                        decoration: BoxDecoration(
                            color: isLowestPrice(cardNum)
                                ? greenHighlight
                                : currentTheme.backgroundColor),
                        child: Text(
                          showPricePerUnit(cardNum),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            backgroundColor: isLowestPrice(cardNum)
                                ? greenHighlight
                                : currentTheme.backgroundColor,
                            color: isLowestPrice(cardNum)
                                ? Colors.white
                                : currentTheme.textTheme.bodyText2?.color,
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
            Visibility(
              visible: showSecondRow,
              maintainState: false,
              child: SizedBox(
                height: 36,
                child: AnimatedOpacity(
                  opacity: secondRowOpaque ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: animationDuration),
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
                              decoration: const InputDecoration(
                                  hintText: 'Qty',
                                  contentPadding: EdgeInsets.only(
                                    bottom: inputContentPadding,
                                  )),
                              style: currentTheme.textTheme.bodyText2,
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
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
                              focusNode: _qtyFocusNodes[cardNum],
                              onSubmitted: (String str) {
                                FocusScope.of(context)
                                    .requestFocus(_itemNameFocusNodes[cardNum]);
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
                              decoration: const InputDecoration(
                                  hintText: 'Item name',
                                  contentPadding: EdgeInsets.only(
                                    bottom: inputContentPadding,
                                  )),
                              style: currentTheme.textTheme.bodyText2,
                              textInputAction: TextInputAction.next,
                              controller: getControllerSafely(
                                  _itemNameControllers, cardNum),
                              focusNode: _itemNameFocusNodes[cardNum],
                              onSubmitted: (String str) {
                                FocusScope.of(context)
                                    .requestFocus(_unitNameFocusNodes[cardNum]);
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
                              decoration: const InputDecoration(
                                  hintText: 'Unit name',
                                  contentPadding: EdgeInsets.only(
                                    bottom: inputContentPadding,
                                  )),
                              style: currentTheme.textTheme.bodyText2,
                              textInputAction: TextInputAction.next,
                              controller: getControllerSafely(
                                  _unitNameControllers, cardNum),
                              focusNode: _unitNameFocusNodes[cardNum],
                              onSubmitted: (String str) {
                                // TODO instead of returning to the top, make textInputAction Done or similar so the keyboard just disappears.
                                if (cardNum == _cardCounter - 1) {
                                  FocusScope.of(context)
                                      .requestFocus(_priceFocusNodes[0]);
                                } else {
                                  FocusScope.of(context).requestFocus(
                                      _priceFocusNodes[cardNum + 1]);
                                }
                              },
                            ),
                          ),
                        )),
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: currentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: dukeBlue,
          actions: [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                clearAll();
              },
            ),
            IconButton(
              icon: const Icon(Icons.remove), //unfold_less will be the opposite
              onPressed: () {
                removeCard();
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                addCard();
              },
            ),
            IconButton(
              icon: const Icon(
                  Icons.unfold_more), //unfold_less will be the opposite
              onPressed: () {
                showHideSecondRow();
              },
            ),
            IconButton(
              icon: const Icon(Icons.invert_colors_off),
              onPressed: () {
                swapTheme();
              },
            ),
          ],
        ),
        body: Center(
            child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(children: buildCardList(_cardCounter)))),
        /* // Floating action buttons at the bottom of the screen.
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
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
        ),*/
      ),
    );
  }
}
