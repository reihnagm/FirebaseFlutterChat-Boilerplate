import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/utils/custom_themes.dart';
import 'package:chatv28/basewidgets/snackbar/snackbar.dart';
import 'package:chatv28/services/cloud_storage.dart';
import 'package:chatv28/services/media.dart';
import 'package:chatv28/utils/box_shadow.dart';
import 'package:chatv28/pages/login.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/basewidgets/button/custom_button.dart';
import 'package:chatv28/basewidgets/custom_input_fields.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({ Key? key }) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late double deviceHeight;
  late double deviceWidth;

  late NavigationService navigation;
  late MediaService mediaService;
  late CloudStorageService cloudStorageService;

  File? file;
  PlatformFile? image;

  GlobalKey<ScaffoldState> globalKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();

  String? imageUrl;
  String? name;
  String? email;
  String? password;

  void chooseAvatar() async {
    PlatformFile? f = await mediaService.pickImageFromLibrary();
    if(f != null) { 
      image = f;
      File? cropped = await ImageCropper.cropImage(
        sourcePath: f.path!,
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: "Crop It"
          toolbarColor: Colors.blueGrey[900],
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false
        ),
        iosUiSettings: const IOSUiSettings(
          minimumAspectRatio: 1.0,
        )
      );  
      if(cropped != null) {
        setState(() => file = cropped);
      } else {
        setState(() => file = null);
      }
    }   
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    navigation = NavigationService();
    mediaService = MediaService();
    cloudStorageService = CloudStorageService();
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
              const SizedBox(height: 80.0),
              pageTitle(),
              const SizedBox(height: 20.0),
              registerPic(),
              const SizedBox(height: 20.0),
              registerForm(),
              const SizedBox(height: 20.0),
              registerButton(),
              const SizedBox(height: 10.0),
              loginAccountLink()
            ],
          ),
        ),
      ),
    );
  }

  Widget registerPic() {
    return  Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        file != null 
        ? Stack(
            children: [
              Container(
                width: 80.0,
                height: 100.0,
                padding: const EdgeInsets.all(10.0),
                child: Image.file(
                  file!,
                  width: 50.0,
                  height: 50.0,
                )
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: InkWell(
                  onTap: () => chooseAvatar(),
                  child: const Icon(
                    Icons.edit,
                    size: 25.0,
                    color: ColorResources.black,
                  ),
                )
              ),
            ],
          )
        : Stack(
            children: [
              Container(
                width: 80.0,
                height: 100.0,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: ColorResources.backgroundBlueSecondary,
                  boxShadow: boxShadow,
                  shape: BoxShape.circle
                ),
                child: const Icon(
                  Icons.group,
                  size: 45.0,
                  color: ColorResources.white,
                ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: InkWell(
                  onTap: () => chooseAvatar(),
                  child: const Icon(
                    Icons.edit,
                    size: 25.0,
                    color: ColorResources.black,
                  ),
                )
              ),
            ],
          ),
      ],
    );
  }

  Widget pageTitle() {
    return SizedBox(
      height: deviceHeight * 0.10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Chatify",
            style: dongleLight.copyWith(
              color: ColorResources.textBlackPrimary,
              fontSize: Dimensions.fontSizeOverLarge,
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

  Widget registerForm() {
    return SizedBox(
      child: Form(
        key: registerFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomTextFormField(
              prefixIcon: const Icon(
                Icons.person,
                size: 20.0,
                color: ColorResources.backgroundBlackPrimary,  
              ),
              onChanged: (val) {
                setState(() {
                  name = val;
                });
              }, 
              onSaved: (val) {
                setState(() {
                  name = val;
                });
              },
              hintText: "", 
              label: Text("Name",
                style: dongleLight.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: ColorResources.textBlackPrimary
                ),
              ),
              obscureText: false
            ),
            const SizedBox(height: 20.0),
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
              label: Text("E-mail Address",
                style: dongleLight.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
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
              label: Text("Password",
                style: dongleLight.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: ColorResources.textBlackPrimary
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget registerButton() {
    return CustomButton(
      onTap: () async {
        if(name == null) {
          ShowSnackbar.snackbar(context, "Name is required", "", ColorResources.error);
          return;
        }
        if(registerFormKey.currentState!.validate()) {
          registerFormKey.currentState!.save();
          if(file != null) {
            try {
              await context.read<AuthenticationProvider>().registerUsingEmailAndPassword(context, name!, email!, password!, image!);  
            } catch(e) {
              debugPrint(e.toString());
            }
          } else {
            ShowSnackbar.snackbar(context, "Avatar is required", "", ColorResources.error);
          }
        }
      },
      height: 40.0,
      isBorder: false,
      isBoxShadow: true,
      isLoading: context.watch<AuthenticationProvider>().registerStatus == RegisterStatus.loading ? true : false,
      btnColor: ColorResources.loaderBluePrimary,
      btnTxt: "Register"
    );
  } 

  Widget loginAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(),
        SizedBox(
          child: Material(
            color: ColorResources.transparent,
            child: InkWell(
              onTap: () {
                navigation.pushNav(context, const LoginPage());
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Login",
                  style: dongleLight.copyWith(
                    color: ColorResources.textBlackPrimary,
                    fontSize: Dimensions.fontSizeSmall
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