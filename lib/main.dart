import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_hooks/flutter_hooks.dart' as hooks;

void main() {
  runApp(
    MaterialApp(
      title: 'Test app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    ),
  );
}

class HomePage extends hooks.HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store(appStateReducer,
        initialState: const State(
          items: [],
          filter: ItemFilter.all,
        ));
    final textController = hooks.useTextEditingController;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home page'),
      ),
    );
  }
}

enum ItemFilter {
  all,
  longTexts,
  shortTexts,
}

@immutable
class State {
  final Iterable<String> items;
  final ItemFilter filter;

  const State({
    required this.items,
    required this.filter,
  });

  Iterable<String> get filteredItems {
    switch (filter) {
      case ItemFilter.all:
        return items;
      case ItemFilter.longTexts:
        return items.where((item) => item.length >= 10);
      case ItemFilter.shortTexts:
        return items.where((item) => item.length <= 3);
    }
  }
}

@immutable
abstract class Action {
  const Action();
}

@immutable
class ChangeFilterTypeAction extends Action {
  final ItemFilter filter;
  const ChangeFilterTypeAction(this.filter);
}

@immutable
abstract class ItemAction extends Action {
  final String item;
  const ItemAction({required this.item});
}

@immutable
class AddItemAction extends ItemAction {
  const AddItemAction({required String item}) : super(item: item);
}

@immutable
class RemoveItemAction extends ItemAction {
  const RemoveItemAction({required String item}) : super(item: item);
}

extension AddRemoveItems<T> on Iterable<T> {
  Iterable<T> operator +(T other) => followedBy([other]);
  Iterable<T> operator -(T other) => where((elements) => elements != other);
}

Iterable<String> addItemReducer(
  Iterable<String> previousItems,
  AddItemAction action,
) =>
    previousItems + action.item;

Iterable<String> removeItemReducer(
  Iterable<String> previousItems,
  RemoveItemAction action,
) =>
    previousItems - action.item;

Reducer<Iterable<String>> itemsReducer = combineReducers<Iterable<String>>([
  TypedReducer<Iterable<String>, AddItemAction>(addItemReducer),
  TypedReducer<Iterable<String>, RemoveItemAction>(removeItemReducer),
]);

ItemFilter itemFilterReducer(
  State oldState,
  Action action,
) {
  if (action is ChangeFilterTypeAction) {
    return action.filter;
  } else {
    return oldState.filter;
  }
}

State appStateReducer(State oldState, action) => State(
      items: itemsReducer(oldState.items, action),
      filter: itemFilterReducer(oldState, action),
    );
