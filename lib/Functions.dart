import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> signUp(String email, String password,String firstN,String lastN) async {
   QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId,isEqualTo: email).get();
   if (querySnapshot.docs.isNotEmpty){
     return 'Account with email exists';
   }
   FirebaseFirestore.instance.collection('users').doc(email).set({
     'email':email,
     'password':password,
     'firstN':firstN,
     'lastN':lastN,
     'points':10
   });

   SharedPreferences prefs = await SharedPreferences.getInstance();
   await prefs.setString('email', email);
   await prefs.setString('firstN', firstN);
   return 'Sign Up Successful';
}

Future<String> logIn(String email,String password) async{
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId,isEqualTo: email).get();
  if (querySnapshot.docs.isEmpty){
    return 'Account with email does not exist';
  }
  DocumentSnapshot snapshot = querySnapshot.docs[0];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('email', email);
  await prefs.setString('firstN', snapshot['firstN']);

  return 'Login Successful';
}

Future<List> getToys() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List toyList = [];
  String currentEmail = prefs.getString('email');
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('toys').where('madeBy',isNotEqualTo: currentEmail).get();
  for (DocumentSnapshot snapshot in querySnapshot.docs){
    QuerySnapshot querySnapshot2 = await snapshot.reference.collection('requests').get();
    List requests = [];
    for (DocumentSnapshot snapshot in querySnapshot2.docs){
      requests.add(snapshot.data());
    }
    toyList.add({
      'cost':snapshot.get('cost'),
      'image':snapshot.get('image'),
      'madeBy':snapshot.get('madeBy'),
      'name':snapshot.get('name'),
      'requests':requests,
      'id':snapshot.id
    });
  }
  return toyList;
}

void addToy(String name, int cost, String image) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String email = prefs.getString('email');
  FirebaseFirestore.instance.collection('toys').add({
    'madeBy':email,
    'cost':cost,
    'name':name,
    'image':image,
  });
}

void deleteToy(String id) async {
  await FirebaseFirestore.instance.collection('toys').doc(id).delete();
}


Future<String> addRequest(String buyingToyID, DocumentReference toy) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String email = prefs.getString('email');


  DocumentSnapshot buyingToy = await FirebaseFirestore.instance.collection(
      'toys').doc(buyingToyID).get();
  DocumentSnapshot sellingToy = await toy.get();

  CollectionReference collectionReference = FirebaseFirestore.instance.collection('toys').doc(buyingToyID).collection('requests');
  QuerySnapshot querySnapshot  = await collectionReference.where(FieldPath.documentId,isEqualTo: email).get();

  if (querySnapshot.docs.isEmpty){
    collectionReference.doc(email).set({
      'email':email,
      'offer':toy,
    });
    return 'Toy added successfully';
  }
  return 'Request already sent';
}

// Do seeMyToys and transactions
// TODO: Test everything once again .Do transactions, work on the different dialog boxes, and then get started on frappe
Future<List> seeMyToys(String id) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String email = prefs.getString('email');

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('toys').where('madeBy',isEqualTo: email).get();
  List myToys = [];
  for (DocumentSnapshot snapshot in querySnapshot.docs){
    QuerySnapshot querySnapshot2 = await snapshot.reference.collection('requests').get();
    List requests = [];
    for (DocumentSnapshot snapshot in querySnapshot2.docs){
      requests.add(snapshot.data());
    }
    myToys.add({
      'cost':snapshot.get('cost'),
      'image':snapshot.get('image'),
      'madeBy':snapshot.get('madeBy'),
      'name':snapshot.get('name'),
      'requests':requests,
      'id':snapshot.id
    });
  }
  return myToys;
}

Future<String> confirmTransaction(String toyId, String offerID) async {
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // String email = prefs.getString('email')!;

  DocumentSnapshot buyingToy = await FirebaseFirestore.instance.collection(
      'toys').doc(toyId).get();
  DocumentSnapshot sellingToy = await FirebaseFirestore.instance.collection(
      'toys').doc(offerID).get();

  Map<String, dynamic> transaction = {
    'person1': buyingToy.get('madeBy'),
    'toy1': buyingToy.reference,
    'person2': sellingToy.get('madeBy'),
    'toy2': sellingToy.reference
  };
  int transactionAmount = (buyingToy.get('cost') - sellingToy.get('cost')).abs;
  DocumentSnapshot buyingUser = await FirebaseFirestore.instance.collection(
      'users').doc(buyingToy.get('madeBy')).get();
  DocumentSnapshot sellingUser = await FirebaseFirestore.instance.collection(
      'users').doc(sellingToy.get('madeBy')).get();
  if (buyingToy.get('cost') > sellingToy.get('cost')) {
    // if (sellingUser.get('cost') < transactionAmount) {
    //   return 'The other person does not have enough points to cover the difference';
    // }
    await buyingUser.reference.update({
      'points': FieldValue.increment(transactionAmount)
    });
    await sellingUser.reference.update({
      'points': FieldValue.increment(-transactionAmount)
    });
  }
  else if (sellingToy.get('cost') > buyingToy.get('cost')) {
    if (buyingUser.get('points') < transactionAmount) {
      return 'You do not have enough points to cover the difference';
    }
    await buyingUser.reference.update({
      'points': FieldValue.increment(-transactionAmount)
    });
    await sellingUser.reference.update({
      'points': FieldValue.increment(transactionAmount)
    });
  }
  await FirebaseFirestore.instance.collection('transactions').add(transaction);
  return "Transaction Successful";
}
Future<List> getUserTransactions() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String email = prefs.getString('email');
  
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('transactions').get();
  List transactions = [];
  for (DocumentSnapshot snapshot in querySnapshot.docs){
    if (snapshot.get('person1')==email || snapshot.get('person2')==email){
      transactions.add(snapshot.data());
    }
  }
  return transactions;
}