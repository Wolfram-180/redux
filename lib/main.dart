import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store(
      reducer,
      initialState: const State.empty(),
      middleware: [
        loadPeopleMiddleware,
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home page'),
      ),
      body: StoreProvider(
        store: store,
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                store.dispatch(
                  const LoadPeopleAction(),
                );
              },
              child: const Text('Load people'),
            ),
            StoreConnector<State, bool>(
              converter: (store) => store.state.isLoading,
              builder: (context, isLoading) {
                if (isLoading) {
                  return const CircularProgressIndicator();
                } else {
                  return const SizedBox();
                }
              },
            ),
            StoreConnector<State, Iterable<Person>?>(
              converter: (store) => store.state.fetchedPersons,
              builder: (context, people) {
                if (people != null) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: people.length,
                      itemBuilder: (context, index) {
                        final person = people.elementAt(index);
                        return ListTile(
                          title: Text(person.name),
                          subtitle: Text(person.age.toString()),
                        );
                      },
                    ),
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

const apiUrl = 'http://127.0.0.1:5500/api/people.json';

@immutable
class Person {
  final String name;
  final int age;

  const Person({
    required this.name,
    required this.age,
  });

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;

  factory Person.fromJsonFactory(Map<String, dynamic> json) {
    return Person(
      name: json['name'],
      age: json['age'],
    );
  }

  @override
  String toString() => 'Person name: $name, age: $age}';
}

Future<Iterable<Person>> getPersons() => HttpClient()
    .getUrl(Uri.parse(apiUrl))
    .then((request) => request.close())
    .then((response) => response.transform(utf8.decoder).join())
    .then((jsonString) => json.decode(jsonString) as List<dynamic>)
    .then((jsonList) => jsonList.map((json) => Person.fromJson(json)));

@immutable
abstract class Action {
  const Action();
}

@immutable
class LoadPeopleAction extends Action {
  const LoadPeopleAction();
}

@immutable
class SuccesfullyFetchedPeopleAction extends Action {
  final Iterable<Person> persons;
  const SuccesfullyFetchedPeopleAction({required this.persons});
}

@immutable
class FailedToFetchPeopleAction extends Action {
  final Object error;
  const FailedToFetchPeopleAction({required this.error});
}

@immutable
class State {
  final bool isLoading;
  final Iterable<Person>? fetchedPersons;
  final Object? error;

  const State({
    required this.isLoading,
    required this.fetchedPersons,
    required this.error,
  });

  const State.empty()
      : isLoading = false,
        fetchedPersons = null,
        error = null;
}

State reducer(State oldState, action) {
  if (action is LoadPeopleAction) {
    return const State(
      isLoading: true,
      fetchedPersons: null,
      error: null,
    );
  } else if (action is SuccesfullyFetchedPeopleAction) {
    return State(
      isLoading: false,
      fetchedPersons: action.persons,
      error: null,
    );
  } else if (action is FailedToFetchPeopleAction) {
    return State(
      isLoading: false,
      fetchedPersons: oldState.fetchedPersons,
      error: action.error,
    );
  } else {
    return oldState;
  }
}

void loadPeopleMiddleware(
  Store<State> store,
  action,
  NextDispatcher next,
) {
  if (action is LoadPeopleAction) {
    getPersons().then(
      (persons) {
        store.dispatch(SuccesfullyFetchedPeopleAction(persons: persons));
      },
      onError: (error) {
        store.dispatch(FailedToFetchPeopleAction(error: error));
      },
    );
  }
  next(action);
}



/* 1 StoreConnector
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
    final store = Store(
      appStateReducer,
      initialState: const State(
        items: [],
        filter: ItemFilter.all,
      ),
    );
    final textController = hooks.useTextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home page'),
      ),
      body: StoreProvider(
        store: store,
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    store.dispatch(
                      const ChangeFilterTypeAction(ItemFilter.all),
                    );
                  },
                  child: const Text('All'),
                ),
                TextButton(
                  onPressed: () {
                    store.dispatch(
                      const ChangeFilterTypeAction(ItemFilter.shortTexts),
                    );
                  },
                  child: const Text('Short texts'),
                ),
                TextButton(
                  onPressed: () {
                    store.dispatch(
                      const ChangeFilterTypeAction(ItemFilter.longTexts),
                    );
                  },
                  child: const Text('Long texts'),
                ),
              ],
            ),
            TextField(
              controller: textController,
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    store.dispatch(
                      AddItemAction(item: textController.text),
                    );
                    textController.clear();
                  },
                  child: const Text('Add'),
                ),
                TextButton(
                  onPressed: () {
                    store.dispatch(
                      RemoveItemAction(item: textController.text),
                    );
                    textController.clear();
                  },
                  child: const Text('Remove'),
                ),
              ],
            ),
            StoreConnector<State, Iterable<String>>(
              converter: (store) => store.state.filteredItems,
              builder: (context, items) {
                return Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items.elementAt(index);
                      return ListTile(
                        title: Text(item),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
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
1 */