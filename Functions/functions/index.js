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
      if (userList.length == 5) {
        return response.send(userList);
      }
    }
    response.send(userList);
  });
});

exports.friendRequestNotification = functions.database.ref("/users/{recipientUid}/friendRequests/{requesterUid}").onCreate(event => {
  const recipientUid = event.params.recipientUid;
  const requesterUid = event.params.requesterUid;

  console.log("recipientUid = ", recipientUid, " and requesterUid = ", requesterUid)

  const getDeviceTokensPromise = admin.database().ref("/users/" + recipientUid + "/tokens").once("value");
  const getRequesterProfilePromise = admin.database().ref("/profiles/" + requesterUid + "/name").once("value");

  return Promise.all([getDeviceTokensPromise, getRequesterProfilePromise]).then(results => {
    const tokensSnapshot = results[0];
    const requesterSnapshot = results[1];

    if (!tokensSnapshot.hasChildren()) {
      return
    }


    const name = requesterSnapshot.val();

    const payload = {
      notification: {
        body: "New friend request from " + name,
        sound: "default"
      }
    };

    const tokens = Object.keys(tokensSnapshot.val());

    return admin.messaging().sendToDevice(tokens, payload).then(response => {
      const tokensToRemove = [];
      response.results.forEach((result, index) => {
        const error = result.error;
        if (error) {
          if (error.code === "messaging/invalid-registration-token" || error.code === "messaging/registration-token-not-registered") {
            tokensToRemove.push(tokensSnapshot.ref.child(tokens[index]).remove());
          }
        }
      });
      return Promise.all(tokensToRemove);
    });
  });
});


exports.messageNotification = functions.database.ref("/users/{recipientUid}/snapsReceived/{senderUid}/snaps/{snapUid}").onCreate(event => {
  const recipientUid = event.params.recipientUid;
  const senderUid = event.params.senderUid;
  const snapUid = event.params.snapUid;

  console.log("recipientUid = ", recipientUid, " senderUid = ", senderUid, " snapUid = ", snapUid);

  const getDeviceTokensPromise = admin.database().ref("/users/" + recipientUid + "/tokens").once("value");
  const getSenderProfilePromise = admin.database().ref("/profiles/" + senderUid + "/name").once("value");
  const getMediaTypePromise = admin.database().ref("/users/"+recipientUid+"/snapsReceived/"+senderUid+"/snaps/"+snapUid+"/mediaType").once("value");

  return Promise.all([getDeviceTokensPromise, getSenderProfilePromise, getMediaTypePromise]).then(results => {
    const tokensSnapshot = results[0];
    const senderSnapshot = results[1];
    const mediaTypeSnapshot = results[2];

    if (!tokensSnapshot.hasChildren()) {
      return
    }

    const name = senderSnapshot.val();
    const mediaType = mediaTypeSnapshot.val();

    const payload = {
      notification: {
        body: "New " + mediaType + " from " + name,
        sound: "default"
      }
    };

    const tokens = Object.keys(tokensSnapshot.val());

    return admin.messaging().sendToDevice(tokens, payload).then(response => {
      const tokensToRemove = [];
      response.results.forEach((result, index) => {
        const error = result.error;
        if (error) {
          if (error.code === "messaging/invalid-registration-token" || error.code === "messaging/registration-token-not-registered") {
            tokensToRemove.push(tokensSnapshot.ref.child(tokens[index]).remove());
          }
        }
      });
      return Promise.all(tokensToRemove);
    });
  });
});
