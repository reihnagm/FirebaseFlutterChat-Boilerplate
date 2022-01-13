import 'package:chatv28/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  late NavigationService navigation;

  GlobalKey<ScaffoldState> globalKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  String? email;
  String? password;

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 180.0),
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
      ),
    );
  }

  Widget pageTitle() {
    return SizedBox(
      height: deviceHeight * 0.10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text("Chatify",
            style: TextStyle(
              color: ColorResources.textBlackPrimary,
              fontSize: 40.0,
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(width: 3.0),
          Icon(
            Icons.chat_bubble_rounded,
            size: 20.0,  
          ),
        ],
      ) 
    );
  }

  Widget loginForm() {
    return SizedBox(
      child: Form(
        key: loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomTextFormField(
              prefixIcon: const Icon(
                Icons.email,
                size: 20.0,
                color: ColorResources.backgroundBlackPrimary,    
              ),
              onSaved: (val) {
                setState(() {
                  email = val;
                });
              }, 
              onChanged: (val) {
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
            const SizedBox(height: 20.0),
            CustomTextPasswordFormField(
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
          context.read<AuthenticationProvider>().loginUsingEmailAndPassword(context, email!, password!);
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
                navigation.pushBackNavReplacement(context, const RegisterPage());
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