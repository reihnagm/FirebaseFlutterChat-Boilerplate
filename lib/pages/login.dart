import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/utils/box_shadow.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/basewidget/button/custom_button.dart';
import 'package:chatv28/basewidget/custom_input_fields.dart';

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

  GlobalKey<ScaffoldState> globalKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  String? email;
  String? password;

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    authenticationProvider = Provider.of<AuthenticationProvider>(context);
    navigation = NavigationService();
    return buildUI();
  }

  Widget buildUI() {
    return Scaffold(
      key: globalKey,
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
            const SizedBox(height: 20.0),
            loginForm(),
            const SizedBox(height: 20.0),
            loginButton(),
            const SizedBox(height: 10.0),
            registerAccountLink()
          ],
        ),
      ),
    );
  }

  Widget pageTitle() {
    return SizedBox(
      height: deviceHeight * 0.10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Chatify",
            style: TextStyle(
              color: ColorResources.textBlackPrimary,
              fontSize: 40.0,
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(width: 3.0),
          const Icon(
            Icons.chat_bubble_rounded,
            size: 20.0,  
          ),
        ],
      ) 
    );
  }

  Widget loginForm() {
    return SizedBox(
      height: deviceHeight * 0.17,
      child: Form(
        key: loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: boxShadow
              ),
              child: CustomTextFormField(
                onSaved: (val) {
                  setState(() {
                    email = val;
                  });
                }, 
                regex: r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+", 
                hintText: "", 
                label: const Text("E-mail Address",
                  style: TextStyle(
                    color: ColorResources.textBlackPrimary
                  ),
                ),
                obscureText: false
              ),
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: boxShadow
              ),
              child: CustomTextPasswordFormField(
                onSaved: (val) {
                  setState(() {
                    password = val;
                  });
                }, 
                regex: r".{8,}", 
                hintText: "", 
                label: const Text("Password",
                  style: TextStyle(
                    color: ColorResources.textBlackPrimary
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget loginButton() {
    return CustomButton(
      onTap: () {
        if(loginFormKey.currentState!.validate()) {
          loginFormKey.currentState!.save();
          authenticationProvider.loginUsingEmailAndPassword(context, email!, password!);
        }
      },
      height: 40.0,
      isBorder: false,
      isBoxShadow: true,
      isLoading: context.watch<AuthenticationProvider>().loginStatus == LoginStatus.loading ? true : false,
      btnColor: ColorResources.loaderBluePrimary,
      btnTxt: "Login"
    );
  } 

  Widget registerAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(),
        SizedBox(
          child: Material(
            color: ColorResources.transparent,
            child: InkWell(
              onTap: () {
                
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Register",
                  style: TextStyle(
                    color: ColorResources.textBlackPrimary,
                    fontSize: Dimensions.fontSizeExtraSmall
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

}