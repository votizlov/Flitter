import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/widgets/customWidgets.dart';
import 'package:path/path.dart' as Path;
import 'appState.dart';
import 'package:firebase_database/firebase_database.dart' as dabase;
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class AuthState extends AppState {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  bool isSignInWithGoogle = false;
  UserModel user;
  String userId;
  dabase.Query _profileQuery;
  List<UserModel> _profileUserModelList;
  UserModel _userModel;

  UserModel get userModel => _userModel;

  UserModel get profileUserModel {
    if (_profileUserModelList != null && _profileUserModelList.length > 0) {
      return user;
    } else {
      return user;
    }
  }

  void removeLastUser() {
    _profileUserModelList.removeLast();
  }

  /// Logout from device
  void logoutCallback() {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    _userModel = null;
    user = null;
    _profileUserModelList = null;
    if (isSignInWithGoogle) {
      //_googleSignIn.signOut();
      logEvent('google_logout');
    }
    //_firebaseAuth.signOut();
    notifyListeners();
  }

  /// Alter select auth method, login and sign up page
  void openSignUpPage() {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    notifyListeners();
  }

  databaseInit() {
    try {
      if (_profileQuery == null) {
        _profileQuery = kDatabase.child("profile").child(user.userId);
        _profileQuery.onValue.listen(_onProfileChanged);
      }
    } catch (error) {
      cprint(error, errorIn: 'databaseInit');
    }
  }

  /// Verify user's credentials for login
  Future<String> signIn(String email, String password,
      {GlobalKey<ScaffoldState> scaffoldKey}) async {
    String uuid;
    final DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        uuid = androidInfo.androidId;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        uuid = iosInfo.identifierForVendor;
      }
    } on Exception {
      print('Failed to get platform version');
      return null;
    }

    SecurityContext context = SecurityContext();
    //context.setTrustedCertificatesBytes(cert);

    try {
      loading = true;
      //var result = await _firebaseAuth.signInWithEmailAndPassword( todo setup auth
      //    email: email, password: password);
      final response = http.post('http://192.168.0.104/flitter/fetch_data.php', body: {
        'id': uuid, //get the username text
        'password': password  //get password text
      });//await http.get('http://192.168.0.104/flitter/fetch_data.php');

      if (== 200) {
        customSnackBar(scaffoldKey, "`login sucsessful");
      }
      kAnalytics.logEvent(name: "test");
      customSnackBar(scaffoldKey, "event logged");
      user = new UserModel();//result.user;
      _userModel = user;
      userId = user.userId;//usder.uid;
      return userId;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'signIn');
      kAnalytics.logLogin(loginMethod: 'email_login');
      //kAnalytics.lo
      customSnackBar(scaffoldKey, error.message);
      // logoutCallback();
      return null;
    }
  }


  /// Create new user's profile in db
  Future<String> signUp(UserModel userModel,
      {GlobalKey<ScaffoldState> scaffoldKey, String password}) async {/*
    try {
      loading = true;
      var result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: password,
      );
      user = result.user;
      authStatus = AuthStatus.LOGGED_IN;
      kAnalytics.logSignUp(signUpMethod: 'register');
      result.user.updateProfile(
          displayName: userModel.displayName, photoURL: userModel.profilePic);

      _userModel = userModel;
      _userModel.key = user.uid;
      _userModel.userId = user.uid;
      createUser(_userModel, newUser: true);
      return user.uid;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'signUp');
      customSnackBar(scaffoldKey, error.message);
      return null;
    }*/
  }

  /// `Create` and `Update` user
  /// IF `newUser` is true new user is created
  /// Else existing user will update with new values
  createUser(UserModel user, {bool newUser = false}) {
    if (newUser) {
      // Create username by the combination of name and id
      user.userName = getUserName(id: user.userId, name: user.displayName);
      kAnalytics.logEvent(name: 'create_newUser');

      // Time at which user is created
      user.createdAt = DateTime.now().toUtc().toString();
    }

    kDatabase.child('profile').child(user.userId).set(user.toJson());
    _userModel = user;
    if (_profileUserModelList != null) {
      _profileUserModelList.last = _userModel;
    }
    loading = false;
  }

  /// Fetch current user profile
  Future<UserModel> getCurrentUser() async {
    try {
      loading = true;
      logEvent('get_currentUSer');
      //user = _firebaseAuth.currentUser;
      if (user != null) {
        authStatus = AuthStatus.LOGGED_IN;
        userId = user.userId;
        getProfileUser();
      } else {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      }
      loading = false;
      return user;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'getCurrentUser');
      authStatus = AuthStatus.NOT_LOGGED_IN;
      return null;
    }
  }

  /// Reload user to get refresh user data
  reloadUser() async {
    /*await user.reload();
    user = _firebaseAuth.currentUser;
    if (user.emailVerified) {
      userModel.isVerified = true;
      // If user verifed his email
      // Update user in firebase realtime kDatabase
      createUser(userModel);
      cprint('UserModel email verification complete');
      logEvent('email_verification_complete',
          parameter: {userModel.userName: user.email});
    }*/
  }


  /// Check if user's email is verified
  Future<bool> emailVerified() async {
    //User user = _firebaseAuth.currentUser;
    return true;//user.emailVerified;
  }


  /// `Update user` profile
  Future<void> updateUserProfile(UserModel userModel,
      {File image, File bannerImage}) async {
    try {
      if (image == null && bannerImage == null) {
        createUser(userModel);
      } else {
        /// upload profile image if not null
        if (image != null) {
          /// get image storage path from server
          userModel.profilePic = await _uploadFileToStorage(image,
              'user/profile/${userModel.userName}/${Path.basename(image.path)}');
          // print(fileURL);
          var name = userModel?.displayName ?? user.displayName;
          //_firebaseAuth.currentUser
          //    .updateProfile(displayName: name, photoURL: userModel.profilePic);
        }

        /// upload banner image if not null
        if (bannerImage != null) {
          /// get banner storage path from server
          userModel.bannerImage = await _uploadFileToStorage(bannerImage,
              'user/profile/${userModel.userName}/${Path.basename(bannerImage.path)}');
        }

        if (userModel != null) {
          createUser(userModel);
        } else {
          createUser(_userModel);
        }
      }

      logEvent('update_user');
    } catch (error) {
      cprint(error, errorIn: 'updateUserProfile');
    }
  }

  Future<String> _uploadFileToStorage(File file, path) async {
    /*var task = _firebaseStorage.ref().child(path);
    var status = await task.putFile(file);
    print(status.state);

    /// get file storage path from server
    return await task.getDownloadURL();*/
    return "asdsa";
  }

  /// `Fetch` user `detail` whoose userId is passed
  Future<UserModel> getuserDetail(String userId) async {
    UserModel user;
    var snapshot = await kDatabase.child('profile').child(userId).once();
    if (snapshot.value != null) {
      var map = snapshot.value;
      user = UserModel.fromJson(map);
      user.key = snapshot.key;
      return user;
    } else {
      return null;
    }
  }

  /// Fetch user profile
  /// If `userProfileId` is null then logged in user's profile will fetched
  getProfileUser({String userProfileId}) {
    try {
      loading = true;
      if (_profileUserModelList == null) {
        _profileUserModelList = [];
      }

      userProfileId = userProfileId == null ? user.userId : userProfileId;
      kDatabase
          .child("profile")
          .child(userProfileId)
          .once()
          .then((DataSnapshot snapshot) {
        if (snapshot.value != null) {
          var map = snapshot.value;
          if (map != null) {
            _profileUserModelList.add(UserModel.fromJson(map));
            if (userProfileId == user.userId) {
              _userModel = _profileUserModelList.last;
              _userModel.isVerified = user.isVerified;
              if (!user.isVerified) {
                // Check if logged in user verified his email address or not
                reloadUser();
              }
              if (_userModel.fcmToken == null) {
                updateFCMToken();
              }
            }

            logEvent('get_profile');
          }
        }
        loading = false;
      });
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'getProfileUser');
    }
  }

  /// if firebase token not available in profile
  /// Then get token from firebase and save it to profile
  /// When someone sends you a message FCM token is used
  void updateFCMToken() {
    if (_userModel == null) {
      return;
    }
    getProfileUser();/*
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      _userModel.fcmToken = token;
      createUser(_userModel);
    });*/
  }

  /// Follow / Unfollow user
  ///
  /// If `removeFollower` is true then remove user from follower list
  ///
  /// If `removeFollower` is false then add user to follower list
  followUser({bool removeFollower = false}) {
    /// `userModel` is user who is looged-in app.
    /// `profileUserModel` is user whoose profile is open in app.
    try {
      if (removeFollower) {
        /// If logged-in user `alredy follow `profile user then
        /// 1.Remove logged-in user from profile user's `follower` list
        /// 2.Remove profile user from logged-in user's `following` list
        profileUserModel.followersList.remove(userModel.userId);

        /// Remove profile user from logged-in user's following list
        userModel.followingList.remove(profileUserModel.userId);
        cprint('user removed from following list', event: 'remove_follow');
      } else {
        /// if logged in user is `not following` profile user then
        /// 1.Add logged in user to profile user's `follower` list
        /// 2. Add profile user to logged in user's `following` list
        if (profileUserModel.followersList == null) {
          profileUserModel.followersList = [];
        }
        profileUserModel.followersList.add(userModel.userId);
        // Adding profile user to logged-in user's following list
        if (userModel.followingList == null) {
          userModel.followingList = [];
        }
        userModel.followingList.add(profileUserModel.userId);
      }
      // update profile user's user follower count
      profileUserModel.followers = profileUserModel.followersList.length;
      // update logged-in user's following count
      userModel.following = userModel.followingList.length;
      kDatabase
          .child('profile')
          .child(profileUserModel.userId)
          .child('followerList')
          .set(profileUserModel.followersList);
      kDatabase
          .child('profile')
          .child(userModel.userId)
          .child('followingList')
          .set(userModel.followingList);
      cprint('user added to following list', event: 'add_follow');
      notifyListeners();
    } catch (error) {
      cprint(error, errorIn: 'followUser');
    }
  }

  /// Trigger when logged-in user's profile change or updated
  /// Firebase event callback for profile update
  void _onProfileChanged(Event event) {
    if (event.snapshot != null) {
      final updatedUser = UserModel.fromJson(event.snapshot.value);
      if (updatedUser.userId == user.userId) {
        _userModel = updatedUser;
      }
      cprint('UserModel Updated');
      notifyListeners();
    }
  }

  User getUser(){
    return new User("asda");
  }
}
