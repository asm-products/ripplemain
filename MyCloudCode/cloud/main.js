
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});

Parse.Cloud.define("sendLinkOnSignup", function(request, response) {
  
  var MessageThread = Parse.Object.extend("MessageThread");
  var UserLinks = Parse.Object.extend("UserLinks");

  var recipientId = request.params.recipientId;

  //----------------------------------
  // Get The Ripple Team PFUser object
  //----------------------------------
  Parse.Cloud.useMasterKey();
  queryTo = new Parse.Query("User");
  var founderId = 'zn3p0nKJPJ';
  queryTo.get(founderId, {
    success: function(_toUser) {
      
      //-------------------------------
      // Create and store messageThread
      //-------------------------------
      var messageThread = new MessageThread();
      // Message
      var sender = {"Username":"Ed"}

      var today = new Date();
      var yyyy = today.getFullYear();
      var mm = today.getMonth()+1;
      var dd = today.getDate();
      var hh = today.getHours();
      var min = today.getMinutes();
      var ss = today.getSeconds();
      if (dd<10) {
        dd = '0'+dd
      }
      if (mm<10) {
        mm = '0'+mm
      }
      today = yyyy + '-' + mm + '-' + dd + ' ' + hh + ':' + min + ':' + ss

      var messageDict = {"Message":"Hi! I'm the founder of Ripple, and I just wanted to say thanks for signing up. I really hope you enjoy using Ripple - click on the link above to start exploring!", "Sender":sender, "Date":today};
      var messages = new Array();
      messages.push(messageDict);
      messageThread.set("Messages", messages);
      // UnreadMarkers
      var unreadMarkers = {}
      unreadMarkers[recipientId] = 1;
      unreadMarkers[founderId] = 0;
      messageThread.set("UnreadMarkers", unreadMarkers);
      // linkString
      var linkString = "http://www.getripple.co/howto.html"
      messageThread.set("linkString", linkString);
      // imageURL (string)
      var imageURL = "http://sites.google.com/site/edrexmusic/images/RippleDrop512.png"
      messageThread.set("imageURL", imageURL);
      // titleString
      messageThread.set("titleString", "Welcome to Ripple!");
      // Originator
      messageThread.set("Originator", _toUser);
      // Store messageThread
      messageThread.save(null, {
        success: function(messageThread) {

          //---------------------------------------------------------------------
          // Update new user's userLinks (NB new user may not have UserLinks yet)
          //---------------------------------------------------------------------
          var recipientQuery = new Parse.Query(UserLinks);
          recipientQuery.equalTo("UserID", recipientId);
          recipientQuery.find({
            success: function(results) {

              if (results.length == 0) {
                var userLinks = new UserLinks();
                userLinks.set('UserID', recipientId);
                var relation = userLinks.relation('MessageThreads');
                relation.add(messageThread);
                userLinks.save();
                console.log("New UserLinks saved");
              } else {
                for (var i = 0; i < results.length; i++) {
                  var object = results[i];
                  var relation = object.relation('MessageThreads');
                  relation.add(messageThread);
                  object.save();
                }
                console.log("UserLinks already existed");
              }
            },
            error: function(error) {
              console.log("Error retrieving all message users");
            }
          });

          //-------------------------------
          // Update Ripple Team's userLinks
          //-------------------------------
          var founderQuery = new Parse.Query(UserLinks);
          founderQuery.equalTo("UserID", founderId);
          founderQuery.find({
            success: function(results) {

              for (var i = 0; i < results.length; i++) {
                var object = results[i];
                var relation = object.relation('MessageThreads');
                relation.add(messageThread);
                object.save();
              }
              response.success('MessageThread storing succeeded');
            },
            error: function(error) {
              console.log("Error retrieving all message users");
              response.error('MessageThread storing failed');
            }
          });

          // Send the sender a notification (and refresh their inbox)
          // var senderQuery = new Parse.Query(Parse.Installation);
          // senderQuery.equalTo("UserID", request.params.senderID);
          // Parse.Push.send({
          //   where: senderQuery,
          //   data: {
          //     alert: "Ed sent you a link",
          //     badge: "Increment"
          //   }
          // }, {
          //   success: function() {
          //     response.success('Notification sent');
          //   },
          //   error: function(error) {
          //     response.error('Notification sending failed');
          //   }
          // });

          // Execute any logic that should take place after the object is saved.
          alert('New object created with objectId: ' + messageThread.id);
        },
        error: function(messageThread, error) {
          // Execute any logic that should take place if the save fails.
          // error is a Parse.Error with an error code and description.
          alert('Failed to create new object, with error code: ' + error.description);
        }
      });
    },
    error: function(error) {
      console.log("Error retrieving user in query!");
    }
  });
});

  





  // // Get all of these selected friends who have signed up to Perch
  // var signedUpQuery = new Parse.Query(HanglyUser);
  // signedUpQuery.containedIn("UserID", friendsToAdd);
  // signedUpQuery.each(function(hanglyUser) {

  //   // Check whether or not the selected friend wants to see the sender
  //   var friendSelectedFriends = hanglyUser.get('WantsToSee');
  //   var friendWantsToSeeMe = false;
  //   if (friendSelectedFriends != undefined) {
  //     for (var i = 0; i < friendSelectedFriends.length; i++) {
  //       var friendTheyWantToSee = friendSelectedFriends[i];

  //       if (friendTheyWantToSee.ID == request.params.senderID) {
  //         friendWantsToSeeMe = true;
  //       }
  //     }
  //   }

  //   // If they want to see me, send both of us a match notification
  //   if (friendWantsToSeeMe)
  //   {
  //     var userName = hanglyUser.get("Username");

  //     // Send the sender a match notification
  //     Parse.Push.send({
  //       where: senderQuery, // Set our Installation query
  //       data: {
  //       alert: "You've got a match - " + userName + " wants to see you tonight!",
  //       badge: "Increment"
  //       }
  //     }, {
  //       success: function() {
          
  //         },
  //       error: function(error) {
          
  //         }
  //     });

  //     // Send the friend a match notification
  //     var friendInstallQuery = new Parse.Query(Parse.Installation);
  //     friendInstallQuery.equalTo("UserID", hanglyUser.get("UserID"));
  //     var senderUserName = request.params.senderName;

  //     Parse.Push.send({
  //       where: friendInstallQuery, // Set our Installation query
  //       data: {
  //         alert: "You've got a match - " + senderUserName + " wants to see you tonight!",
  //         badge: "Increment"
  //       }
  //     }, {
  //       success: function() {
          
  //       },
  //       error: function(error) {
          
  //       }
  //     });
  //   }
  //   // If they don't want to see me, send them a normal notification
  //   else
  //   {
  //     // Send the friend a normal notification
  //     var friendInstallQuery = new Parse.Query(Parse.Installation);
  //     friendInstallQuery.equalTo("UserID", hanglyUser.get("UserID"));
  //     var senderUserName = request.params.senderName;

  //     Parse.Push.send({
  //       where: friendInstallQuery, // Set our Installation query
  //       data: {
  //         alert: senderUserName + " wants to see you tonight!",
  //         badge: "Increment"
  //       }
  //     }, {
  //       success: function() {
          
  //       },
  //       error: function(error) {
          
  //       }
  //     });
  //   }

  //   // Add the sender to the friend's WantToSeeMe entry if they are not there already
  //   var selectedFriendWantsToSeeMeArray = hanglyUser.get('WantToSeeMe');
  //   var senderIncluded = false;
  //   if (selectedFriendWantsToSeeMeArray != undefined) {
  //     for (var i = 0; i < selectedFriendWantsToSeeMeArray.length; i++) {
  //       var friendWhoWantsToSeeThem = selectedFriendWantsToSeeMeArray[i];

  //       if (friendWhoWantsToSeeThem.ID == request.params.senderID) {
  //         senderIncluded = true;
  //       }
  //     }
  //   }
  //   else {
  //     selectedFriendWantsToSeeMeArray = new Array();
  //   }
  //   if (senderIncluded == false) {
      
  //     var userDict = {"ID":request.params.senderID, "Name":request.params.senderName};
  //     selectedFriendWantsToSeeMeArray.push(userDict);
  //     hanglyUser.set("WantToSeeMe", selectedFriendWantsToSeeMeArray);
  //     hanglyUser.save();
  //   }
  // });
// });
