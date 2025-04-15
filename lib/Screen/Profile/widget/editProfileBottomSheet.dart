import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:customer/Helper/Color.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../../../../Helper/String.dart';
import '../../../../Provider/SettingProvider.dart';
import '../../../../Provider/UserProvider.dart';
import '../../../Helper/ApiBaseHelper.dart';
import '../../../Helper/Session.dart';
import '../../../ui/styles/DesignConfig.dart';
import '../../../ui/styles/Validators.dart';
import '../../../ui/widgets/AppBtn.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class EditProfileBottomSheet extends StatefulWidget {
  const EditProfileBottomSheet({super.key});
  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet>
    with TickerProviderStateMixin {
  FocusNode? passFocus = FocusNode();
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _changeUserDetailsKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  Animation? buttonSqueezeanimation1;
  AnimationController? buttonController1;
  Widget getUserImage(String profileImage, VoidCallback? onBtnSelected) {
    return InkWell(
        child: Stack(
          children: <Widget>[
            Container(
              margin: const EdgeInsetsDirectional.only(end: 20),
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.white,),),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child:
                    Consumer<UserProvider>(builder: (context, userProvider, _) {
                  return userProvider.profilePic != ''
                      ? networkImageCommon(userProvider.profilePic, 64, false,
                          height: 64, width: 64,)
                      : imagePlaceHolder(62, context);
                },),
              ),
            ),
            if (context.read<UserProvider>().userId != "")
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  end: 20,
                  bottom: 5,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primarytheme,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primarytheme,),),
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.white,
                      size: 10,
                    ),
                  ),),
          ],
        ),
        onTap: () {
          if (mounted) {
            if (context.read<UserProvider>().userId != "") onBtnSelected!();
          }
        },);
  }

  Widget setNameField() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              controller: nameController,
              decoration: InputDecoration(
                  label: Text(getTranslated(context, "NAME_LBL")!),
                  fillColor: Theme.of(context).colorScheme.white,
                  border: InputBorder.none,),
              validator: (val) => validateUserName(
                  val!,
                  getTranslated(context, 'USER_REQUIRED'),
                  getTranslated(context, 'USER_LENGTH'),),
            ),
          ),
        ),
      );
  Widget setEmailField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            readOnly: (context.read<UserProvider>().loginType != GOOGLE_TYPE)
                ? false
                : true,
            controller: emailController,
            decoration: InputDecoration(
                label: Text(getTranslated(context, "EMAILHINT_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none,),
            validator: (val) => validateEmail(
                val!,
                getTranslated(context, 'EMAIL_REQUIRED'),
                getTranslated(context, 'VALID_EMAIL'),),
          ),
        ),
      ),
    );
  }

  Widget setMobileField() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              readOnly: context.read<UserProvider>().loginType != PHONE_TYPE
                  ? false
                  : true,
              controller: mobileController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              decoration: InputDecoration(
                labelText: getTranslated(context, "MOBILEHINT_LBL"),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none,
              ),
              validator: (val) => validateMob(
                val!,
                getTranslated(context, 'MOB_REQUIRED'),
                getTranslated(context, 'VALID_MOB'),
                check: false,
              ),
            ),
          ),
        ),
      );
  Widget saveButton(String title, VoidCallback? onBtnSelected) {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 8.0, end: 8.0, top: 15.0),
        child: AppBtn(
            title: title,
            btnAnim: buttonSqueezeanimation1,
            btnCntrl: buttonController1,
            onBtnSelected: onBtnSelected,),);
  }

  Future<void> _imgFromGallery() async {
    try {
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        final File image = File(result.files.single.path!);
        print('file image***$image');
        final ImageCropper imageCropper = ImageCropper();
        final CroppedFile? croppedImage =
            await imageCropper.cropImage(sourcePath: image.path, uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],),
          IOSUiSettings(title: 'Crop Image', aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],),
        ],);
        if (croppedImage != null) {
          final File croppedFile = File(croppedImage.path);
          await setProfilePic(croppedFile);
        } else {}
      } else {}
    } catch (e) {
      setSnackbar(getTranslated(context, "PERMISSION_NOT_ALLOWED")!, context);
    }
  }

  Future<void> setProfilePic(File image) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final request = http.MultipartRequest("POST", getUpdateUserApi);
        request.headers.addAll(headers);
        request.fields[USER_ID] = context.read<UserProvider>().userId;
        final mimeType = lookupMimeType(image.path);
        final extension = mimeType!.split("/");
        final pic = await http.MultipartFile.fromPath(
          IMAGE,
          image.path,
          contentType: MediaType('image', extension[1]),
        );
        request.files.add(pic);
        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final getdata = json.decode(responseString);
        final bool error = getdata["error"];
        final String? msg = getdata['message'];
        if (!error) {
          final data = getdata["data"];
          var image;
          image = data[IMAGE];
          final settingProvider =
              Provider.of<SettingProvider>(context, listen: false);
          settingProvider.setPrefrence(IMAGE, image!);
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setProfilePic(image!);
          setSnackbar(getTranslated(context, 'PROFILE_UPDATE_MSG')!, context);
        } else {
          setSnackbar(msg!, context);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Future<void> _playAnimation(AnimationController ctrl) async {
    try {
      await ctrl.forward();
    } on TickerCanceled {
      return;

    }
  }

  Future<bool> validateAndSave(GlobalKey<FormState> key) async {
    final form = key.currentState!;
    form.save();
    if (form.validate()) {
      _playAnimation(buttonController1!);
      context.read<UserProvider>().setProgress(true);
      print("change details***${mobileController.text}");
      setUpdateUser(context.read<UserProvider>().userId, "", "",
          nameController.text, emailController.text, mobileController.text,);
      return true;
    }
    return false;
  }

  Future<void> setUpdateUser(String userID,
      [oldPwd, newPwd, username, userEmail, userMob,]) async {
    final apiBaseHelper = ApiBaseHelper();
    final data = {USER_ID: userID};
    if ((oldPwd != "") && (newPwd != "")) {
      data[OLDPASS] = oldPwd;
      data[NEWPASS] = newPwd;
    }
    if (username != "") {
      data[USERNAME] = username;
    }
    if (userEmail != "") {
      data[EMAIL] = userEmail;
    }
    if (userMob != "") {
      data[MOBILE] = userMob;
    }
    print("profile data****$data");
    final Map<String, dynamic> result =
        await apiBaseHelper.postAPICall(getUpdateUserApi, data);
    print("profileupdate--result-->$result");
    final bool error = result["error"];
    final String? msg = result["message"];
    await buttonController1!.reverse();
    Navigator.of(context).pop();
    if (!error) {
      final settingProvider =
          Provider.of<SettingProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (username != "") {
        setState(() {
          settingProvider.setPrefrence(USERNAME, username);
          userProvider.setName(username);
        });
      }
      if (userEmail != "") {
        setState(() {
          settingProvider.setPrefrence(EMAIL, userEmail);
          userProvider.setEmail(userEmail);
        });
      }
      if (userMob != "") {
        setState(() {
          settingProvider.setPrefrence(MOBILE, userMob);
          userProvider.setMobile(userMob);
        });
      }
      setSnackbar(getTranslated(context, 'USER_UPDATE_MSG')!, context);
    } else {
      setSnackbar(msg!, context);
    }
    context.read<UserProvider>().setProgress(false);
  }

  @override
  void initState() {
    buttonController1 = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this,);
    buttonSqueezeanimation1 = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController1!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ),);
    Future.delayed(Duration.zero).then(
      (value) {
        nameController.text = context.read<UserProvider>().curUserName;
        emailController.text = context.read<UserProvider>().email;
        mobileController.text = context.read<UserProvider>().mob;
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return Wrap(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,),
                  child: Form(
                    key: _changeUserDetailsKey,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            bottomSheetHandle(context),
                            bottomsheetLabel("EDIT_PROFILE_LBL", context),
                            Selector<UserProvider, String>(
                                selector: (_, provider) => provider.profilePic,
                                builder: (context, profileImage, child) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0,),
                                    child: getUserImage(
                                        profileImage, _imgFromGallery,),
                                  );
                                },),
                            Selector<UserProvider, String>(
                                selector: (_, provider) => provider.curUserName,
                                builder: (context, userName, child) {
                                  return setNameField();
                                },),
                            Selector<UserProvider, String>(
                                selector: (_, provider) => provider.email,
                                builder: (context, userEmail, child) {
                                  return setEmailField();
                                },),
                            Selector<UserProvider, String>(
                                selector: (_, provider) => provider.mob,
                                builder: (context, userMob, child) {
                                  return setMobileField();
                                },),
                            saveButton(
                                getTranslated(context, 'SAVE_LBL')!,
                                !userProvider.getProgress
                                    ? () {
                                        validateAndSave(_changeUserDetailsKey);
                                      }
                                    : () {},),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    super.dispose();
  }
}
