import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class ToyTraderFirebaseUser {
  ToyTraderFirebaseUser(this.user);
  final User user;
  bool get loggedIn => user != null;
}

ToyTraderFirebaseUser currentUser;
bool get loggedIn => currentUser?.loggedIn ?? false;
Stream<ToyTraderFirebaseUser> toyTraderFirebaseUserStream() => FirebaseAuth
    .instance
    .authStateChanges()
    .debounce((user) => user == null && !loggedIn
        ? TimerStream(true, const Duration(seconds: 1))
        : Stream.value(user))
    .map<ToyTraderFirebaseUser>(
        (user) => currentUser = ToyTraderFirebaseUser(user));
