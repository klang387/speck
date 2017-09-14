// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);


exports.findUser = functions.https.onRequest((request, response) => {
  const searchTerm = request.query.name;
  const profilesRef = admin.database().ref('/profiles');
  profilesRef.once('value').then(function(snapshot) {
    const users = snapshot.val();
    var userList = [];
    for (var key in users) {
      var user = users[key];
      var name = user["name"];
      if (name.toLowerCase().includes(searchTerm.toLowerCase())){
        userList.push(key);
      }
    }
    response.send(userList);
  });
});
