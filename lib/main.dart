// 2

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        loadPersonImageMiddleware,
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
              converter: (store) => store.state.sortedFetchedPersons,
              builder: (context, people) {
                if (people != null) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: people.length,
                      itemBuilder: (context, index) {
                        final person = people.elementAt(index);
                        final infoWidget = Text('${person.age} years old');

                        final Widget subTitle = person.imageData == null
                            ? infoWidget
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  infoWidget,
                                  Image.memory(person.imageData!, height: 200),
                                ],
                              );

                        final Widget trailing = person.isLoading
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: () {
                                  store.dispatch(
                                    LoadPersonImageAction(
                                      personId: person.id,
                                    ),
                                  );
                                },
                                child: const Text('Load image'),
                              );

                        return ListTile(
                          title: Text(person.name),
                          subtitle: subTitle,
                          trailing: trailing,
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
  final String id;
  final String name;
  final int age;
  final String imageUrl;
  final Uint8List? imageData;
  final bool isLoading;

  Person copiedWith(
    bool? isLoading,
    Uint8List? imageData,
  ) =>
      Person(
        id: id,
        name: name,
        age: age,
        imageUrl: imageUrl,
        imageData: imageData ?? this.imageData,
        isLoading: isLoading ?? this.isLoading,
      );

  const Person({
    required this.name,
    required this.age,
    required this.id,
    required this.imageUrl,
    required this.imageData,
    required this.isLoading,
  });

  Person.fromJson(Map<String, dynamic> json)
      : id = json['id'].toString(),
        name = json['name'].toString(),
        age = json['age'] as int,
        imageUrl = json['image_url'].toString(),
        imageData = null,
        isLoading = false;

  @override
  String toString() => 'Person id = $id, name: $name, age: $age}';
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

  Iterable<Person>? get sortedFetchedPersons => fetchedPersons?.toList()
    ?..sort(
      (p1, p2) => int.parse(p1.id).compareTo(
        int.parse(p2.id),
      ),
    );

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

@immutable
class LoadPersonImageAction extends Action {
  final String personId;

  const LoadPersonImageAction({
    required this.personId,
  });
}

@immutable
class SuccessfullyLoadedPersonImageAction extends Action {
  final String personId;
  final Uint8List imageData;

  const SuccessfullyLoadedPersonImageAction({
    required this.personId,
    required this.imageData,
  });
}

State reducer(State oldState, action) {
  if (action is SuccessfullyLoadedPersonImageAction) {
    final person = oldState.fetchedPersons?.firstWhere(
      (person) => person.id == action.personId,
    );
    if (person != null) {
      return State(
        error: oldState.error,
        isLoading: false,
        fetchedPersons:
            oldState.fetchedPersons?.where((p) => p.id != person.id).followedBy(
          [
            person.copiedWith(
              false,
              action.imageData,
            ),
          ],
        ),
      );
    } else {
      return oldState;
    }
  } else if (action is LoadPersonImageAction) {
    final person = oldState.fetchedPersons?.firstWhere(
      (person) => person.id == action.personId,
    );
    if (person != null) {
      return State(
        error: oldState.error,
        isLoading: false,
        fetchedPersons:
            oldState.fetchedPersons?.where((p) => p.id != person.id).followedBy(
          [
            person.copiedWith(true, null),
          ],
        ),
      );
    } else {
      return oldState;
    }
  } else if (action is LoadPeopleAction) {
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

void loadPersonImageMiddleware(
  Store<State> store,
  action,
  NextDispatcher next,
) {
  if (action is LoadPersonImageAction) {
    final person = store.state.fetchedPersons?.firstWhere(
      (p) => p.id == action.personId,
    );

    if (person != null) {
      final url = person.imageUrl;
      final bundle = NetworkAssetBundle(Uri.parse(url));
      bundle
          .load(url)
          .then((data) => data.buffer.asUint8List())
          .then((imageData) {
        store.dispatch(
          SuccessfullyLoadedPersonImageAction(
            personId: person.id,
            imageData: imageData,
          ),
        );
      });
    }
  }
  next(action);
}
// 2

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