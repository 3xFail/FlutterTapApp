import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

class SimpleBlocDelgate extends BlocDelegate {
  @override
  void onTransition(Transition transition) {
    print(transition);
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(error);
  }
}

void main() {
  BlocSupervisor().delegate = SimpleBlocDelgate();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<MyApp> {
  final CounterBloc _counterBloc = CounterBloc();
  final ThemeBloc _themeBloc = ThemeBloc();

  @override
  Widget build(BuildContext context) {
    return BlocProviderTree(
      blocProviders: [
        BlocProvider<CounterBloc>(bloc: _counterBloc),
        BlocProvider<ThemeBloc>(bloc: _themeBloc)
      ],
      child: BlocBuilder(
        bloc: _themeBloc,
        builder: (_, ThemeData theme) {
          return MaterialApp(
            title: 'Flutter Demo',
            home: CounterPage(),
            theme: theme,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _counterBloc.dispose();
    _themeBloc.dispose();
    super.dispose();
  }
}

bool _upgradeBuyButtonEnable = false;

class UpgradeCard extends StatelessWidget {

  //final int index;
  VoidCallback onPressed;
  final String upgradeName;
  final String upgradeCost;
  final IconData upgradeIcon;
  //final int optionalThing;

  UpgradeCard(this.upgradeName, this.upgradeCost, this.onPressed, {this.upgradeIcon = Icons.add_circle});


  @override
  Widget build(BuildContext context) {
    if(!_upgradeBuyButtonEnable)
    {
      onPressed = null;
    }
    return Card(
      child: Column(
        children: [
          Text('Upgrade Available: $upgradeName', 
          style: TextStyle(
            fontSize: 18.0
            ),
          ),
          Text('Cost: $upgradeCost', 
          style: TextStyle(
            fontSize: 18.0
            ),
          ),
          IconButton(icon:Icon(upgradeIcon), onPressed: onPressed, iconSize: 120)
        ]
      )
    );
  }
}

class CounterPage extends StatelessWidget {
  
  //final List<int> _items = List.generate(100, (int index) => index);

  @override
  Widget build(BuildContext context) {
    final CounterBloc _counterBloc = BlocProvider.of<CounterBloc>(context);
    //final ThemeBloc _themeBloc = BlocProvider.of<ThemeBloc>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: BlocBuilder<CounterEvent, CounterState>(
        bloc: _counterBloc,
        builder: (BuildContext context, CounterState state) {
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              
              Text('Current count: ${state.bank}', style: TextStyle(fontSize: 30.0),
                
              ),
              Expanded(child: UpgradeCard(
                'Better Clicks ${CounterBloc.randomValue}',
                state.purchaseCost.toString(),
                () {
                  _counterBloc.dispatch(Purchase());
                },
              )),
              SizedBox(
                  width:double.infinity,
                  child: RaisedButton(
                    child: Icon(Icons.add, size: 90.0,),
                    onPressed: () =>
                        _counterBloc.dispatch(IncrementCounter()),
                  )
              ),
              // RaisedButton
            ],
          );
        },
      ),
    );
  }
}

abstract class CounterEvent {  }
class IncrementCounter extends CounterEvent{ }
class Purchase extends CounterEvent{}

const int _kMinRandomValue = 1;
const int _kMaxRandomValue = 10; 

class CounterState {
  final int purchaseCost;
  final int bank;
  final String upgradeName;

  CounterState(this.purchaseCost, this.bank, {this.upgradeName});

  CounterState copyWith({
    int purchaseCost,
    int bank,
    String upgradeName
  }) {
    return CounterState(
      purchaseCost ?? this.purchaseCost,
      bank ?? this.bank
    );
  }
}

class CounterBloc extends Bloc<CounterEvent, CounterState> {

  CounterBloc(){
    randomValue = _kMinRandomValue + rnd.nextInt(_kMaxRandomValue - _kMinRandomValue);
  }

  @override
  CounterState get initialState => CounterState(10, 0);

  static Random rnd = Random();
  final int min = 1;
  final int max = 10;
  
  static int randomValue;
  final int startingCost = 10;
  final int percentageCostIncrease = 15;

  int incrementCount = 1;

  @override
  Stream<CounterState> mapEventToState(CounterEvent event) async * {
    if(event is IncrementCounter) {

      // purchaseButtonEnabled = purchaseCost <= bank;
      if((currentState.bank+incrementCount) >= currentState.purchaseCost)
      {
        _upgradeBuyButtonEnable = true;
      }

      yield CounterState(
        currentState.purchaseCost,
        currentState.bank + incrementCount
      );
    }

    if(event is Purchase) {


      // Deal with bank amount changes
      incrementCount += randomValue;
      randomValue = _kMinRandomValue + rnd.nextInt(_kMaxRandomValue - _kMinRandomValue);
      final newPurchaseCost = currentState.purchaseCost + incrementCount;
      final newBank = currentState.bank - currentState.purchaseCost;

      //Update the button state
      if(newBank < newPurchaseCost)
      {
        _upgradeBuyButtonEnable = false;
      }

      yield CounterState(
        newPurchaseCost,
        newBank
      );
    }
  }
}

enum ThemeEvent { toggle }

class ThemeBloc extends Bloc<ThemeEvent, ThemeData> {
  @override
  ThemeData get initialState => ThemeData.dark();

  @override
  Stream<ThemeData> mapEventToState(ThemeEvent event) async* {
    switch (event) {
      case ThemeEvent.toggle:
        yield currentState == ThemeData.dark()
            ? ThemeData.light()
            : ThemeData.dark();
        break;
    }
  }
}
