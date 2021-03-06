import 'dart:async';
import 'dart:convert';
import 'package:flutter_session/flutter_session.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/class/checklogin.dart';
import 'package:test/class/myuser.dart';
import 'package:test/screens/main_screen.dart';
import 'package:test/screens/signup.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class SigninPage extends StatefulWidget {
  static String routeName = "/signin";
  SigninPage({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  late Timer timer;
  String configs = '';

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  Future<void> getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      configs = prefs.getString('configs');
    });
  }

  void alertDialog(String msg, String type) {
    Icon icon = Icon(Icons.info_outline, color: Colors.lightBlue);
    switch (type) {
      case "Success":
        icon = Icon(Icons.check_circle_outline, color: Colors.lightGreen);
        break;
      case "Error":
        icon = Icon(Icons.error_outline, color: Colors.redAccent);
        break;
      case "Warning":
        icon = Icon(Icons.warning_amber_outlined, color: Colors.orangeAccent);
        break;
      case "Infomation":
        icon = Icon(Icons.info_outline, color: Colors.lightBlue);
        break;
    }

    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          timer = Timer(Duration(seconds: 5), () {
            Navigator.of(context, rootNavigator: true).pop();
          });

          return AlertDialog(
            title: Row(children: [icon, Text(" " + type)]),
            content: Text(msg),
          );
        }).then((val) {
      if (timer.isActive) {
        timer.cancel();
      }
    });
  }

  void showErrorDialog(String error) {
    //MyWidget.showMyAlertDialog(context, "Error", error);
    alertDialog(error, 'Error');
  }

  void showSuccessDialog(String success) {
    //MyWidget.showMyAlertDialog(context, "Success", success);
    alertDialog(success, 'Success');
  }

  Future<void> signInCheck() async {
    try {
      if (userNameController.text == '') {
        _btnController.reset();
        showErrorDialog('Please Enter Username');
        return;
      } else if (passwordController.text == '') {
        _btnController.reset();
        showErrorDialog('Please Enter Password');
        return;
      }

      var username = userNameController.text;
      var password = passwordController.text;
      var token = await FlutterSession().get("token");

      var url = Uri.parse(configs +
          '/RTLS/CheckLogin/' +
          username +
          '/' +
          password +
          '/' +
          token);
      http.Response response = await http.get(url);

      var data = json.decode(response.body);
      CheckLogin checkResult = CheckLogin.fromJson(data);

      if (response.statusCode != 200 && response.statusCode != 404) {
        showErrorDialog('Error Http Requests signInCheck');
        return;
      }

      if (checkResult.status == "200") {
        setState(() {
          userNameController.text = '';
          passwordController.text = '';
        });
        await FlutterSession().set('uid', checkResult.result!.uid);
        await FlutterSession().set('username', checkResult.result!.userName);
        _btnController.reset();
        Navigator.pushReplacementNamed(context, MainScreen.routeName);
        return;
      } else if (checkResult.status == "404") {
        setState(() {
          userNameController.text = '';
          passwordController.text = '';
        });
        _btnController.reset();
        showErrorDialog(checkResult.message.toString());
        return;
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, SigninPage.routeName);
    }
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 0, top: 10, bottom: 10),
              child: Icon(Icons.keyboard_arrow_left, color: Colors.black),
            ),
            Text('Back',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))
          ],
        ),
      ),
    );
  }

  Widget _titleWidget() {
    /*return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
          text: 'H',
          style: TextStyle(
              fontSize: 42, fontWeight: FontWeight.w700, color: Colors.black),
          children: [
            TextSpan(
              text: '-',
              //style: TextStyle(color: Color(0xffe46b10), fontSize: 42),
              style: TextStyle(color: Colors.yellow.shade800, fontSize: 42),
            ),
            TextSpan(
              text: 'RTLS',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 42),
            ),
          ]),
    );*/
    return Image.asset(
      'assets/RTLS_logo.png',
      height: MediaQuery.of(context).size.height * .15,
      width: MediaQuery.of(context).size.width * .75,
      fit: BoxFit.cover,
    );
  }

  Widget _contextWidget() {
    return Column(
      children: <Widget>[
        _entryFieldUsername("Username"),
        _entryFieldPassword("Password", isPassword: true),
      ],
    );
  }

  Widget _entryFieldUsername(String title, {bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(
            height: 10,
          ),
          TextField(
              controller: userNameController,
              obscureText: isPassword,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  fillColor: Color(0xfff3f3f4),
                  filled: true))
        ],
      ),
    );
  }

  Widget _entryFieldPassword(String title, {bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(
            height: 10,
          ),
          TextField(
              controller: passwordController,
              obscureText: isPassword,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  fillColor: Color(0xfff3f3f4),
                  filled: true))
        ],
      ),
    );
  }

  Widget _signInButtonWidget() {
    return InkWell(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: RoundedLoadingButton(
            color: Colors.yellow.shade900,
            successColor: Color(0xfffbb448).withAlpha(100),
            //width: 200,
            controller: _btnController,
            onPressed: () => signInCheck(),
            valueColor: Colors.black,
            //borderRadius: 30,
            child: Text('LOGIN', style: TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Divider(
                thickness: 1,
              ),
            ),
          ),
          Text('or'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Divider(
                thickness: 1,
              ),
            ),
          ),
          SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }

  Widget _facebookButton() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xff1959a9),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    topLeft: Radius.circular(5)),
              ),
              alignment: Alignment.center,
              child: Text('',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w400)),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xff2872ba),
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(5),
                    topRight: Radius.circular(5)),
              ),
              alignment: Alignment.center,
              child: Text('Log in with Facebook',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signUpLabelWidget() {
    return InkWell(
      onTap: () {
        Navigator.pushReplacementNamed(context, SignupPage.routeName);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20),
        padding: EdgeInsets.all(15),
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Don\'t have an account ?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Register',
              style: TextStyle(
                  color: Color(0xfff79c4f),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        body: Container(
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned(
              top: -height * .15,
              right: -MediaQuery.of(context).size.width * .4,
              child: Container()),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: height * .12),
                  _titleWidget(),
                  SizedBox(height: 50),
                  _contextWidget(),
                  SizedBox(height: 20),
                  _signInButtonWidget(),
                  //SizedBox(height: 2),
                  /*Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.centerRight,
                    child: Text('Forgot Password ?',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  _divider(),
                  _facebookButton(),
                  SizedBox(height: 20),*/
                  _signUpLabelWidget(),
                ],
              ),
            ),
          ),
          //Positioned(top: 40, left: 0, child: _backButton()),
        ],
      ),
    ));
  }
}
