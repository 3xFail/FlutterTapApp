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
            title: 'Flutter TapApp',
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



class UpgradeCard extends StatelessWidget {

  //final int index;
  final VoidCallback onPressed;
  final String upgradeName;
  final String upgradeCost;
  final IconData upgradeIcon;
  //final int optionalThing;

  UpgradeCard(this.upgradeName, this.upgradeCost, this.onPressed, {this.upgradeIcon = Icons.add_circle});



  @override
  Widget build(BuildContext context) {
    
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
  
  @override
  Widget build(BuildContext context) {
    final CounterBloc _counterBloc = BlocProvider.of<CounterBloc>(context);
    //final ThemeBloc _themeBloc = BlocProvider.of<ThemeBloc>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Flutter TapApp')),
      body: BlocBuilder<CounterEvent, CounterState>(
        bloc: _counterBloc,
        builder: (BuildContext context, CounterState state) {
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              
              Text('Current count: ${state.bank}', style: TextStyle(fontSize: 30.0),
                
              ),
              Expanded(child: UpgradeCard(
                'Better Clicks ${CounterBloc.upgradeRandomValue}',
                state.upgradePurchaseCost.toString(), _counterBloc.upgradeBuyButtonEnable == true ? 
                () {
                  _counterBloc.dispatch(UpgradePurchase());
                } : null,
              )),
              Expanded(child: UpgradeCard('+${CounterBloc.accumRandomValue} Accumulator', state.accumPurchaseCost.toString(), _counterBloc.accumulatorBuyButtonEnable == true ? 
                () {
                  _counterBloc.dispatch(AccumPurchase());
                } : null),),
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
class UpgradePurchase extends CounterEvent{}
class AccumIncrementCounter extends CounterEvent{}
class AccumPurchase extends CounterEvent{}



const int _kMinRandomValue = 1;
const int _kMaxRandomValue = 10; 

class CounterState {
  final int upgradePurchaseCost;
  final int accumPurchaseCost;
  final int bank;
  final String upgradeName;

  CounterState(this.upgradePurchaseCost, this.accumPurchaseCost, this.bank, {this.upgradeName});

  CounterState copyWith({
    int upgradePurchaseCost,
    int accumPurchaseCost,
    int bank,
    String upgradeName
  }) {
    return CounterState(
      upgradePurchaseCost ?? this.upgradePurchaseCost,
      accumPurchaseCost ?? this.accumPurchaseCost,
      bank ?? this.bank
    );
  }
}

class CounterBloc extends Bloc<CounterEvent, CounterState> {

  bool _upgradeBuyButtonEnable = false;
  bool get upgradeBuyButtonEnable => _upgradeBuyButtonEnable;
  int incrementCount = 1;
  int accumIncrement = 0;
  static Random rnd = Random();
  final int min = 1;
  final int max = 10;
  static int upgradeRandomValue = _kMinRandomValue + rnd.nextInt(_kMaxRandomValue - _kMinRandomValue);
  static int accumRandomValue = _kMinRandomValue + rnd.nextInt(_kMaxRandomValue - _kMinRandomValue);

  final int startingCost = 10;
  final int percentageCostIncrease = 15;

  Timer accumTimer;
  

  @override
  CounterState get initialState => CounterState(10, 100, 0);

  bool _accumulatorBuyButtonEnable = false;
  bool get accumulatorBuyButtonEnable => _accumulatorBuyButtonEnable;

  

  @override
  Stream<CounterState> mapEventToState(CounterEvent event) async * {
    if(event is IncrementCounter) {

      // purchaseButtonEnabled = purchaseCost <= bank;
      if((currentState.bank+incrementCount) >= currentState.upgradePurchaseCost)
      {
        _upgradeBuyButtonEnable = true;
      }

      if((currentState.bank + incrementCount) >= currentState.accumPurchaseCost)
      {
        _accumulatorBuyButtonEnable = true;
      }

      yield CounterState(
        currentState.upgradePurchaseCost,
        currentState.accumPurchaseCost,
        currentState.bank + incrementCount
      );
    }

    if(event is UpgradePurchase) {


      // Deal with bank amount changes
      incrementCount += upgradeRandomValue;
      upgradeRandomValue = _kMinRandomValue + rnd.nextInt(_kMaxRandomValue - _kMinRandomValue);
      final newPurchaseCost = currentState.upgradePurchaseCost + incrementCount;
      final newBank = currentState.bank - currentState.upgradePurchaseCost;

      //Update the button state
      if(newBank < newPurchaseCost)
      {
        _upgradeBuyButtonEnable = false;
      }
      if(newBank < currentState.accumPurchaseCost)
      {
        _accumulatorBuyButtonEnable = false;
      }
      yield CounterState(
        newPurchaseCost,
        currentState.accumPurchaseCost,
        newBank
      );
    }

    if(event is AccumPurchase)
    {
      accumIncrement += accumRandomValue;

      if(accumIncrement == accumRandomValue)
      {
        accumTimer = Timer.periodic(Duration(seconds: 1), (Timer t)=>(){this.dispatch(AccumIncrementCounter());});
      }
      
      if((currentState.bank-currentState.accumPurchaseCost) < currentState.upgradePurchaseCost)
      {
          _upgradeBuyButtonEnable = false;
      }
      if((currentState.bank-currentState.accumPurchaseCost) < (currentState.accumPurchaseCost*2))
      {
          _accumulatorBuyButtonEnable = false;
      }

      yield CounterState(
        currentState.upgradePurchaseCost, 
        (currentState.accumPurchaseCost*2), 
        (currentState.bank-currentState.accumPurchaseCost));
    }
    if(event is AccumIncrementCounter)
    {
        if((currentState.bank + accumIncrement) >= currentState.upgradePurchaseCost)
        {
          _upgradeBuyButtonEnable = true;
        }

        if((currentState.bank + accumIncrement) >= currentState.accumPurchaseCost)
        {
         _accumulatorBuyButtonEnable = true;
        }

        accumRandomValue = _kMinRandomValue + rnd.nextInt(_kMaxRandomValue - _kMinRandomValue);
        
        yield CounterState(
          currentState.upgradePurchaseCost,
          currentState.accumPurchaseCost,
          currentState.bank + accumIncrement 
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
