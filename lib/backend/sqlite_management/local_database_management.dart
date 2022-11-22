import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/global_uses/enum_generation.dart';
import 'package:chat_app/models/call_log.dart';
import 'package:chat_app/models/latest_message_from_connection.dart';
import 'package:chat_app/models/previous_message.dart';
import 'package:chat_app/models/connection_primary_info.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
//for important table
  final String _importantTableData = "__Important_table_data__";
//all columns
  final String _colUsername = "Username";
  final String _colUserMail = "User_mail";
  final String _colToken = "Token";
  final String _colProfileImagePath = "Profile_image_path";
  final String _colProfileImageUrl = "Profile_Image_url";
  final String _colAbout = "About";
  final String _colWallpaper = "Chat_wallpaper";
  final String _colNotification = "Notification_status";
  final String _colMobileNumber = "User_mobile_number";
  final String _colAccountCreationDate = "Account_Creation_date";
  final String _colAccountCreationTime = "Account_Creation_time";

//for call logs
  final String _callLogData = "__call_logs__";

//all columns
  final String _colCallLogUsername = "username";
  final String _colCallLogDateTime = "date_time";
  final String _colCallLogIspicked = "isPicked";
   final String _colCallLogIsCaller = "isCaller";
  final String _colCallLogProfilePic = "profile_pic";

  // For chat messages with connection
  final String _colActualMessage = "Message";
  final String _colMessageType = "Message_Type";
  final String _colMessageDate = "Message_Date";
  final String _colMessageTime = "Message_Time";
  final String _colMessageHolder = "Message_Holder";

  // Create Singleton Objects(Only Created once in the whole application)
  static late LocalDatabase _localStorageHelper =
      LocalDatabase._createInstance();
  static late Database _database;

  // Instantiate the obj
  LocalDatabase._createInstance(); //named constructor

  //For accessing the Singleton object
  factory LocalDatabase() {
    _localStorageHelper = LocalDatabase._createInstance();
    return _localStorageHelper;
  }

//getter for taking instance of database
  Future<Database> get database async {
    _database = await initializeDatabase();
    return _database;
  }

  //making a database
  Future<Database> initializeDatabase() async {
    // Get the directory path to store the database
    final String desiredPath = await getDatabasesPath();

    //creates a hidden folder for the databases
    final Directory newDirectory =
        await Directory(desiredPath + "/.Databases/").create();
    final String path = newDirectory.path + "/spark_local_storage.db";

    // create the database
    final Database getDatabase = await openDatabase(path, version: 1);
    return getDatabase;
  }

  //creae table to store important data using username as primary key
  Future<void> createTableToStoreImportantData() async {
    Database db = await database;

    try {
      await db.execute(
          """CREATE TABLE $_importantTableData($_colUsername TEXT PRIMARY KEY, 
          $_colUserMail TEXT, $_colToken TEXT, $_colProfileImagePath TEXT,
           $_colProfileImageUrl TEXT, $_colAbout TEXT, $_colWallpaper TEXT,
            $_colNotification TEXT, $_colMobileNumber TEXT,
             $_colAccountCreationDate TEXT, $_colAccountCreationTime TEXT)""");
    } catch (e) {
      print("Error in createTableToStoreImportantData: ${e.toString()}");
    }
  }

//insert or update important data table
  Future<bool> insertOrUpdateDataForThisAccount({
    required String userName,
    required String userMail,
    required String userToken,
    required String userAbout,
    required String profileImagePath,
    required String profileImageUrl,
    String? userAccCreationDate,
    String? userAccCreationTime,
    String chatWallpaper = "",
    String purpose = "insert",
  }) async {
    try {
      final Database db = await database;

      if (purpose != 'insert') {
        final int updateResult = await db.rawUpdate(
            "UPDATE $_importantTableData SET $_colToken = '$userToken', $_colAbout = '$userAbout', $_colProfileImagePath = '$profileImagePath', $_colProfileImageUrl = '$profileImageUrl',  $_colUserMail = '$userMail', $_colAccountCreationDate = '$userAccCreationDate', $_colAccountCreationTime = '$userAccCreationTime' WHERE $_colUsername = '$userName'");

        print('Update Result is: $updateResult');
      } else {
        final Map<String, dynamic> _accountData = <String, dynamic>{};

        _accountData[_colUsername] = userName;
        _accountData[_colUserMail] = userMail;
        _accountData[_colToken] = userToken;
        _accountData[_colProfileImagePath] = profileImagePath;
        _accountData[_colProfileImageUrl] = profileImageUrl;
        _accountData[_colAbout] = userAbout;
        _accountData[_colWallpaper] = chatWallpaper;
        _accountData[_colMobileNumber] = '';
        _accountData[_colNotification] = '1';
        _accountData[_colAccountCreationDate] = userAccCreationDate;
        _accountData[_colAccountCreationTime] = userAccCreationTime;

        await db.insert(_importantTableData, _accountData);
      }

      return true;
    } catch (e) {
      print(
          'Error in Insert or Update operations of important data table: ${e.toString()}');
      return false;
    }
  }

  //create table to store messages for connections
  Future<void> createTableForEveryUser({required String username}) async {
    try {
      final Database db = await database;

      await db.execute(
          "CREATE TABLE $username($_colActualMessage TEXT, $_colMessageType TEXT, $_colMessageHolder TEXT, $_colMessageDate TEXT, $_colMessageTime TEXT, $_colProfileImagePath TEXT)");
    } catch (e) {
      print("Error in Creating Table For Every User: ${e.toString()}");
    }
  }

  //insert messages for conections
  Future<void> insertMessageInUserTable(
      {required String userName,
      required String actualMessage,
      required ChatMessageType chatMessageTypes,
      required MessageHolderType messageHolderType,
      required String messageDateLocal,
      required String messageTimeLocal,
      required String profilePic}) async {
    try {
      final Database db = await database;

      Map<String, String> tempMap = <String, String>{};

      tempMap[_colActualMessage] = actualMessage;
      tempMap[_colMessageType] = chatMessageTypes.toString();
      tempMap[_colMessageHolder] = messageHolderType.toString();
      tempMap[_colMessageDate] = messageDateLocal;
      tempMap[_colMessageTime] = messageTimeLocal;
      tempMap[_colProfileImagePath] = profilePic;

      final int rowAffected = await db.insert(userName, tempMap);
      print('Row Affected: $rowAffected');
    } catch (e) {
      print('Error in Insert Message In User Table: ${e.toString()}');
    }
  }

  //get any field data from the importantTableData using username
  Future<String?> getParticularFieldDataFromImportantTable(
      {required String userName,
      required GetFieldForImportantDataLocalDatabase getField}) async {
    try {
      final Database db = await database;

      final String? _particularSearchField = _getFieldName(getField);

      List<Map<String, Object?>> getResult = await db.rawQuery(
          "SELECT $_particularSearchField FROM $_importantTableData WHERE $_colUsername = '$userName'");

      return getResult[0].values.first.toString();
    } catch (e) {
      print(
          'Error in getParticularFieldDataFromImportantTable: ${e.toString()}');
      return null;
    }
  }

  ////get username for any user from the importantTableData using email
  Future<String?> getUserNameForAnyUser(String userEmail) async {
    try {
      final Database db = await database;

      List<Map<String, Object?>> result = await db.rawQuery(
          "SELECT $_colUsername FROM $_importantTableData WHERE $_colUserMail='$userEmail'");

      return result[0].values.first.toString();
    } catch (e) {
      print('error in getting current user\'s username');
      return null;
    }
  }

  //return field name
  String? _getFieldName(GetFieldForImportantDataLocalDatabase getField) {
    switch (getField) {
      case GetFieldForImportantDataLocalDatabase.userName:
        return _colUsername;
      case GetFieldForImportantDataLocalDatabase.userEmail:
        return _colUserMail;
      case GetFieldForImportantDataLocalDatabase.token:
        return _colToken;
      case GetFieldForImportantDataLocalDatabase.profileImagePath:
        return _colProfileImagePath;
      case GetFieldForImportantDataLocalDatabase.profileImageUrl:
        return _colProfileImageUrl;
      case GetFieldForImportantDataLocalDatabase.about:
        return _colAbout;
      case GetFieldForImportantDataLocalDatabase.wallPaper:
        return _colWallpaper;
      case GetFieldForImportantDataLocalDatabase.mobileNumber:
        return _colMobileNumber;
      case GetFieldForImportantDataLocalDatabase.notification:
        return _colNotification;
      case GetFieldForImportantDataLocalDatabase.accountCreationDate:
        return _colAccountCreationDate;
      case GetFieldForImportantDataLocalDatabase.accountCreationTime:
        return _colAccountCreationTime;
    }
  }

  //get all conections username and about
  Future<List<String>> extractAllConnectionsUsernames() async {
    try {
      final Database db = await database;

      List<String> allConnectionsUsernames = [];
      //extract all usernames excluding the current users's
      List<Map<String, Object?>> result = await db.rawQuery(
          """SELECT $_colUsername FROM $_importantTableData WHERE $_colUserMail != "${FirebaseAuth.instance.currentUser!.email.toString()}" """);

      for (int i = 0; i < result.length; i++) {
        allConnectionsUsernames.add(result[i].values.first.toString());
      }
      return allConnectionsUsernames;
    } catch (e) {
      print('error in getting all connectons usernames : ${e.toString()}');
      return [];
    }
  }

  //get all conections username and about
  Future<List<String>> extractAllUsernamesIncludingCurrentUser() async {
    try {
      final Database db = await database;

      List<String> allUsernames = [];
      //extract all usernames including the current users's
      List<Map<String, Object?>> result = await db
          .rawQuery("""SELECT $_colUsername FROM $_importantTableData """);

      for (int i = 0; i < result.length; i++) {
        allUsernames.add(result[i].values.first.toString());
      }
      return allUsernames;
    } catch (e) {
      print('error in getting all usernames : ${e.toString()}');
      return [];
    }
  }

  //get all conections username and about
  Future<List<ConnectionPrimaryInfo>> getConnectionPrimaryInfo() async {
    try {
      final Database db = await database;

      List<ConnectionPrimaryInfo> allConnectionsPrimaryInfo = [];
      //extract all usernames and about excluding the current users's
      List<Map<String, Object?>> result = await db.rawQuery(
          """SELECT $_colUsername, $_colAbout, $_colProfileImagePath FROM $_importantTableData WHERE $_colUserMail != "${FirebaseAuth.instance.currentUser!.email.toString()}" """);

      for (int i = 0; i < result.length; i++) {
        Map<String, dynamic> tempMap = result[i];
        allConnectionsPrimaryInfo.add(ConnectionPrimaryInfo.toJson(tempMap));
      }
      return allConnectionsPrimaryInfo;
    } catch (e) {
      print(
          'error in getting all connectons primary info from local : ${e.toString()}');
      return [];
    }
  }

  //get all prevoius messages for a particular connection
  Future<List<PreviousMessageStructure>> getAllPreviousMessages(
      String connectionUserName) async {
    try {
      final Database db = await database;

      final List<Map<String, Object?>> result =
          await db.rawQuery("SELECT * from $connectionUserName");

      List<PreviousMessageStructure> takePreviousMessages = [];

      for (int i = 0; i < result.length; i++) {
        Map<String, dynamic> tempMap = result[i];
        takePreviousMessages.add(PreviousMessageStructure.toJson(tempMap));
      }

      return takePreviousMessages;
    } catch (e) {
      print("Error in getAllPreviousMessages: ${e.toString}");
      return [];
    }
  }

  //get last sent messages from connections
  Future<List<LatestMessageFromConnection>>
      getLatestMessageFromConnections() async {
    try {
      final Database db = await database;

      List<LatestMessageFromConnection> lastestMessageFromConnections = [];

      List<Map<String, Object?>> getUsernames = await db.rawQuery(
          """SELECT $_colUsername FROM $_importantTableData WHERE $_colUserMail != "${FirebaseAuth.instance.currentUser!.email.toString()}" """);
      //WHERE $_colMessageHolder == "${MessageHolderType.connectedUsers.toString()}"
      if (getUsernames.isNotEmpty) {
        for (int i = 0; i < getUsernames.length; i++) {
          List<Map<String, Object?>> result = await db.rawQuery(
              """SELECT * FROM ${getUsernames[i].values.first.toString()} """);

          if (result.isNotEmpty) {
            Map<String, dynamic> tempMap = result[result.length - 1];
            lastestMessageFromConnections.add(
                LatestMessageFromConnection.toJson(
                    userName: getUsernames[i].values.first.toString(),
                    map: tempMap));
          }
        }
      }

      return lastestMessageFromConnections;
    } catch (e) {
      print(
          'error in getting last messages from connections : ${e.toString()}');
      return [];
    }
  }

  // Table for call log
  Future<bool> createTableForCallLogs() async {
    try {
      final Database db = await database;

      await db.execute(
          """CREATE TABLE $_callLogData($_colCallLogUsername Text, $_colCallLogProfilePic TEXT, $_colCallLogDateTime TEXT, $_colCallLogIspicked TEXT, $_colCallLogIsCaller TEXT )""");
      return true;
    } catch (e) {
      print(
          "Error in Local Storage Table creation For call logs: ${e.toString()}");
      return false;
    }
  }

  /// Insert data in call logs Table
  Future<bool> insertDataInCallLogsTable(
      {required String username,
      required String dateTime,
      required String profilePic,
      required bool isCaller,
      required bool isPicked}) async {
    try {
      final Database db = await database;
      final Map<String, dynamic> _callLogMap = <String, dynamic>{};

      _callLogMap[_colCallLogUsername] = username;
      _callLogMap[_colCallLogDateTime] = dateTime;
      _callLogMap[_colCallLogProfilePic] = profilePic;
       _callLogMap[_colCallLogIsCaller] = isCaller.toString();
      _callLogMap[_colCallLogIspicked] = isPicked.toString();

      await db.insert(_callLogData, _callLogMap);

      return true;
    } catch (e) {
      print("Error: call logs Table Data insertion Error: ${e.toString()}");
      return false;
    }
  }

  //get call logs
  Future<List<CallLog>> getCallLogs() async {
    try {
      final Database db = await database;

      List<CallLog> takeCallLogs = [];

    final List<Map<String, Object?>> result =
          await db.rawQuery("SELECT * from $_callLogData");

      if (result.isNotEmpty) {
        for (int i = 0; i < result.length; i++) {
          Map<String, dynamic> tempMap = result[i];
          takeCallLogs.add(CallLog.toJson(tempMap));
        }
      }

      return takeCallLogs;
    } catch (e) {
      print("Error in getting call logs: ${e.toString()}");
      return [];
    }
  }
}