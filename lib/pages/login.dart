import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/widgets/custom_button.dart';
import 'package:chatv28/widgets/custom_input_fields.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({ Key? key }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late double deviceHeight;
  late double deviceWidth;

  late AuthenticationProvider authenticationProvider;
  late NavigationService navigation;

  final loginFormKey = GlobalKey<FormState>();

  String? email;
  String? password;

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    authenticationProvider = Provider.of<AuthenticationProvider>(context);
    navigation = GetIt.instance.get<NavigationService>();
    return buildUI();
  }

  Widget buildUI() {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: deviceWidth * 0.03,
          vertical: deviceHeight * 0.02
        ),
        height: deviceHeight * 0.98,
        width: deviceWidth * 0.97,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            pageTitle(),
            SizedBox(height: deviceHeight * 0.04),
            loginForm(),
            SizedBox(height: deviceHeight * 0.05),
            loginButton(context),
            SizedBox(height: deviceHeight * 0.02),
            registerAccountLink()
          ],
        ),
      ),
    );
  }

  Widget pageTitle() {
    return SizedBox(
      height: deviceHeight * 0.10,
      child: const Text("Chatify",
        style: TextStyle(
          color: Colors.white,
          fontSize: 40.0,
          fontWeight: FontWeight.w400
        ),
      ),
    );
  }

  Widget loginForm() {
    return SizedBox(
      height: deviceHeight * 0.20,
      child: Form(
        key: loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomTextFormField(
              onSaved: (val) {
                setState(() {
                  email = val;
                });
              }, 
              regex: r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+", 
              hintText: "E-mail Address", 
              obscureText: false
            ),
            CustomTextFormField(
              onSaved: (val) {
                setState(() {
                  password = val;
                });
              }, 
              regex: r".{8,}", 
              hintText: "Password", 
              obscureText: true
            )
          ],
        ),
      ),
    );
  }

  Widget loginButton(BuildContext context) {
    return CustomButton(
      onTap: () {
        if(loginFormKey.currentState!.validate()) {
          loginFormKey.currentState!.save();
          authenticationProvider.loginUsingEmailAndPassword(context, email!, password!);
        }
      },
      isLoading: context.watch<AuthenticationProvider>().loginStatus == LoginStatus.loading ? true : false,
      isBoxShadow: false,
      btnTxt: "Login"
    );
  } 

  Widget registerAccountLink() {
    return GestureDetector(
      onTap: () {},
      child: const SizedBox(
        child: Text("Don't have an account",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.0
          ),
        ),
      ),
    );
  }

}