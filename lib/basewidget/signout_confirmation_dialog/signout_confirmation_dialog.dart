import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';

class SignOutConfirmationDialog extends StatelessWidget {
  const SignOutConfirmationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge, 
              vertical: 50.0
            ),
            child: Text("Apakah kamu yakin ingin keluar?", 
              style: TextStyle(
                fontSize: Dimensions.fontSizeSmall
              ), 
              textAlign: TextAlign.center
            ),
          ),
          const Divider(
            height: 0.0, 
            color: ColorResources.hintColor
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                onTap: () async {
                  await context.read<AuthenticationProvider>().logout(context);
                },
                child: Consumer<AuthenticationProvider>(
                  builder: (BuildContext context, AuthenticationProvider authenticationProvider, Widget? child) {
                    return Container(
                      padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: ColorResources.backgroundBlueSecondary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10.0)
                        )
                      ),
                      child: authenticationProvider.logoutStatus == LogoutStatus.loading 
                      ? Text("...", 
                          style: TextStyle(
                            color: ColorResources.white,
                            fontSize: Dimensions.fontSizeSmall
                          )
                        )
                      : Text("Ya", 
                          style: TextStyle(
                            color: ColorResources.white,
                            fontSize: Dimensions.fontSizeSmall
                          )
                        ),
                    );   
                  },
                )
              )),
              Expanded(
                child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: ColorResources.white, 
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(10.0)
                    )
                  ),
                  child: Text("Tidak", 
                    style: TextStyle(
                      color: ColorResources.black,
                      fontSize: Dimensions.fontSizeSmall,
                    )
                  ),
                ),
              )),
            ]
          ),
        ]
      ),
    );
  }
}
