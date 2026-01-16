import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage();
  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Column(children: [Text("Login Page")]));
  }
}
