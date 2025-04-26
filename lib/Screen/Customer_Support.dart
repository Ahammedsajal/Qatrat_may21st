import 'dart:async';
import 'dart:io';

import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/ui/widgets/AppBtn.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/SimpleAppBar.dart';
import 'Chat.dart';
import '../Helper/Color.dart';
import 'package:customer/Helper/Session.dart';
import 'package:flutter/material.dart';
import '../Helper/Constant.dart';
import '../ui/widgets/SimBtn.dart';
import '../Helper/String.dart';
import '../Model/Model.dart';
import 'package:file_picker/file_picker.dart';

import 'HomePage.dart';

class customerSupport extends StatefulWidget {
  const customerSupport({super.key});
  @override
  _customerSupportState createState() => _customerSupportState();
}

class _customerSupportState extends State<customerSupport>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isProgress = false;
  Animation? buttonSqueezeanimation;
  late AnimationController buttonController;
  bool _isNetworkAvail = true;
  List<Model> typeList = [];
  List<Model> ticketList = [];
  List<Model> statusList = [];
  List<Model> tempList = [];
  String? type;
  String? email;
  String? title;
  String? desc;
  String? status;
  String? id;
 

  FocusNode? nameFocus;
  FocusNode? emailFocus;
  FocusNode? descFocus;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final descController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool edit = false;
  bool show = false;
  bool fabIsVisible = true;
  ScrollController controller = ScrollController();
  int offset = 0;
  int total = 0;
  int curEdit = -1;
  bool isLoadingmore = true;
   File? _attachment;
  @override
  void initState() {
    super.initState();
    statusList = [
      Model(id: "3", title: "Resolved"),
      Model(id: "5", title: "Reopen"),
    ];
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this,);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ),);
    controller = ScrollController();
    controller.addListener(() {
      setState(() {
        fabIsVisible =
            controller.position.userScrollDirection == ScrollDirection.forward;
        if (controller.offset >= controller.position.maxScrollExtent &&
            !controller.position.outOfRange) {
          isLoadingmore = true;
          if (offset < total) getTicket();
        }
      });
    });
    getType();
    getTicket();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    emailController.dispose();
    descController.dispose();
  }

  @override
 @override
@override
Widget build(BuildContext context) {
  // Detect RTL so “startFloat” always puts FAB on the physical left
  final isRTL = Directionality.of(context) == TextDirection.rtl;

  return Scaffold(
    appBar: getSimpleAppBar(
      getTranslated(context, 'customer_SUPPORT')!,
      context,
    ),

    // In LTR, startFloat is left; in RTL, endFloat is left
    floatingActionButtonLocation: isRTL
        ? FloatingActionButtonLocation.endFloat
        : FloatingActionButtonLocation.startFloat,

    floatingActionButton: Padding(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: fabIsVisible ? 1 : 0,
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              edit = false;
              show = !show;
              clearAll();
            });
          },
          heroTag: null,
          backgroundColor: Theme.of(context).colorScheme.primarytheme,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    ),

    body: _isNetworkAvail
        ? (_isLoading
            ? shimmer(context)
            : Stack(
                children: [
                  SingleChildScrollView(
                    controller: controller,
                    child: Form(
                      key: _formkey,
                      child: Column(
                        children: [
                          // “New Ticket” form
                          if (show)
                            Card(
                              elevation: 0,
                              margin: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    setType(),
                                    const SizedBox(height: 8),
                                    setEmail(),
                                    const SizedBox(height: 8),
                                    setTitle(),
                                    const SizedBox(height: 8),
                                    setDesc(),
                                    const SizedBox(height: 12),
                                    attachmentSection(),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (edit) statusDropDown(),
                                        const Spacer(),
                                        sendButton(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Ticket list or empty state
                          if (ticketList.isNotEmpty)
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: (offset < total)
                                  ? ticketList.length + 1
                                  : ticketList.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                if (index == ticketList.length &&
                                    isLoadingmore) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primarytheme,
                                    ),
                                  );
                                }
                                return ticketItem(index);
                              },
                            )
                          else
                            SizedBox(
                              height: deviceHeight! -
                                  kToolbarHeight -
                                  MediaQuery.of(context).padding.top,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      getTranslated(
                                          context, 'NO_TICKETS_YET')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          edit = false;
                                          show = true;
                                          clearAll();
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                      label: Text(
                                        getTranslated(
                                            context, 'CREATE_NEW_TICKET')!,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primarytheme,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // global loading indicator
                  showCircularProgress(
                    context,
                    _isProgress,
                    Theme.of(context).colorScheme.primarytheme,
                  ),
                ],
              ))
        : noInternet(context),
  );
}


Future<void> _pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.media, // Allows images, videos, etc.
  );
  if (result != null) {
    setState(() {
      _attachment = File(result.files.single.path!);
    });
  }
}
  Widget setType() {
    return DropdownButtonFormField(
      iconEnabledColor: Theme.of(context).colorScheme.fontColor,
      hint: Text(
        getTranslated(context, 'SELECT_TYPE')!,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
      ),
      decoration: InputDecoration(
        filled: true,
        isDense: true,
        fillColor: Theme.of(context).colorScheme.lightWhite,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.fontColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.lightWhite),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      value: type,
      style: Theme.of(context)
          .textTheme
          .titleSmall!
          .copyWith(color: Theme.of(context).colorScheme.fontColor),
      onChanged: (String? newValue) {
        if (mounted) {
          setState(() {
            type = newValue;
          });
        }
      },
      items: typeList.map((Model user) {
        return DropdownMenuItem<String>(
          value: user.id,
          child: Text(
            user.title!,
          ),
        );
      }).toList(),
    );
  }
  Widget attachmentSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ElevatedButton.icon(
        onPressed: _pickFile,
        icon: const Icon(Icons.attach_file),
        label: const Text('Add Attachment'),
      ),
      if (_attachment != null)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              // You can show a preview if it’s an image, or just the file name
              Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.fontColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _attachment!.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _attachment = null;
                  });
                },
              )
            ],
          ),
        ),
    ],
  );
}




  Future<void> validateAndSubmit() async {
    if (edit) {
      if ((type == null || status == null) ||
          (status == null && type == null)) {
        setSnackbar(getTranslated(context, 'SELEC_TYPE')!, context);
      } else if (validateAndSave()) {
        checkNetwork();
      }
    } else {
      if (type == null) {
        setSnackbar(getTranslated(context, 'SELEC_TYPE')!, context);
      } else if (validateAndSave()) {
        checkNetwork();
      }
    }
  }

  Future<void> checkNetwork() async {
    final bool avail = await isNetworkAvailable();
    if (avail) {
      sendRequest();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
        await buttonController.reverse();
      });
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {
      return;
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  setEmail() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        keyboardType: TextInputType.emailAddress,
        focusNode: emailFocus,
        textInputAction: TextInputAction.next,
        controller: emailController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
        validator: (val) => validateEmail(
            val!,
            getTranslated(context, 'EMAIL_REQUIRED'),
            getTranslated(context, 'VALID_EMAIL'),),
        onSaved: (String? value) {
          email = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, 'EMAILHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal,),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setTitle() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        controller: nameController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
        validator: (val) =>
            validateField(val!, getTranslated(context, 'FIELD_REQUIRED')),
        onSaved: (String? value) {
          title = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, 'TITLE'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal,),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setDesc() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        focusNode: descFocus,
        controller: descController,
        maxLines: null,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
        validator: (val) =>
            validateField(val!, getTranslated(context, 'FIELD_REQUIRED')),
        onSaved: (String? value) {
          desc = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, 'DESCRIPTION'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal,),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode? nextFocus,) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  Future<void> getType() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final Map parameter = {};
        apiBaseHelper.postAPICall(getTicketTypeApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            final data = getdata["data"];
            typeList =
                (data as List).map((data) => Model.fromSupport(data)).toList();
          } else {
            setSnackbar(msg!, context);
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
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

  Future<void> getTicket() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          USER_ID: context.read<UserProvider>().userId,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };
        apiBaseHelper.postAPICall(getTicketApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            total = int.parse(getdata["total"]);
            if (offset < total) {
              tempList.clear();
              final data = getdata["data"];
              tempList =
                  (data as List).map((data) => Model.fromTicket(data)).toList();
              ticketList.addAll(tempList);
              offset = offset + perPage;
            }
          } else {
            if (msg != "Ticket(s) does not exist") setSnackbar(msg!, context);
            isLoadingmore = false;
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
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

  Widget sendButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SimBtn(
          width: 0.4,
          height: 35,
          title: getTranslated(context, 'SEND'),
          onBtnSelected: () {
            validateAndSubmit();
          },),
    );
  }

  Future<void> sendRequest() async {
    if (mounted) {
      setState(() {
        _isProgress = true;
      });
    }
    try {
      final data = {
        USER_ID: context.read<UserProvider>().userId,
        SUB: title,
        DESC: desc,
        TICKET_TYPE: type,
        EMAIL: email,
      };
      if (edit) {
        data[TICKET_ID] = id;
        data[STATUS] = status;
      }
      apiBaseHelper.postAPICall(edit ? editTicketApi : addTicketApi, data).then(
          (getdata) {
        final bool error = getdata["error"];
        final String msg = getdata["message"];
        if (!error) {
          final data = getdata["data"];
          if (mounted) {
            setState(() {
              if (edit) {
                ticketList[curEdit] = Model.fromTicket(data[0]);
              } else {
                ticketList.add(Model.fromTicket(data[0]));
              }
            });
          }
        }
        setSnackbar(msg, context);
        setState(() {
          edit = false;
          _isProgress = false;
          clearAll();
        });
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  clearAll() {
    type = null;
    email = null;
    title = null;
    desc = null;
    FocusScope.of(context).unfocus();
  }

  Widget ticketItem(int index) {
    Color back;
    String? status = ticketList[index].status;
    if (status == "1") {
      back = Colors.orange;
      status = "Pending";
    } else if (status == "2") {
      back = Colors.cyan;
      status = "Opened";
    } else if (status == "3") {
      back = Colors.green;
      status = "Resolved";
    } else if (status == "5") {
      back = Colors.cyan;
      status = "Reopen";
    } else {
      back = Colors.red;
      status = "Close";
    }
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => Chat(
                  id: ticketList[index].id,
                  status: ticketList[index].status,
                ),
              ),);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Type : ${ticketList[index].type!}"),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                        color: back,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4.0)),),
                    child: Text(
                      status,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.white),
                    ),
                  ),
                ],
              ),
              Text(
                  "${getTranslated(context, "TITLE")!} : ${ticketList[index].title!}",),
              Text(
                "${getTranslated(context, "DESCRIPTION")!} : ${ticketList[index].desc!}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                  "${getTranslated(context, "DATE")!} : ${ticketList[index].date!}",),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    InkWell(
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(start: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2,),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.lightWhite,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4.0)),),
                          child: Text(
                            getTranslated(context, 'EDIT')!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontSize: 11,),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            edit = true;
                            show = true;
                            curEdit = index;
                            id = ticketList[index].id;
                            emailController.text = ticketList[index].email!;
                            nameController.text = ticketList[index].title!;
                            descController.text = ticketList[index].desc!;
                            type = ticketList[index].typeId;
                          });
                        },),
                    InkWell(
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(start: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2,),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.lightWhite,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4.0)),),
                          child: Text(
                            getTranslated(context, 'CHAT')!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontSize: 11,),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => Chat(
                                  id: ticketList[index].id,
                                  status: ticketList[index].status,
                                ),
                              ),);
                        },),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  statusDropDown() {
    return Container(
      padding: const EdgeInsets.only(top: 10.0),
      width: MediaQuery.of(context).size.width * .4,
      child: DropdownButtonFormField(
        iconEnabledColor: Theme.of(context).colorScheme.fontColor,
        hint: Text(
          getTranslated(context, 'SELECT_TYPE')!,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal,),
        ),
        decoration: InputDecoration(
          filled: true,
          isDense: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        value: status,
        style: Theme.of(context)
            .textTheme
            .titleSmall!
            .copyWith(color: Theme.of(context).colorScheme.fontColor),
        onChanged: (String? newValue) {
          if (mounted) {
            setState(() {
              status = newValue;
            });
          }
        },
        items: statusList.map((Model user) {
          return DropdownMenuItem<String>(
            value: user.id,
            child: Text(
              user.title!,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        noIntImage(),
        noIntText(context),
        noIntDec(context),
        AppBtn(
          title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            _playAnimation();
            Future.delayed(const Duration(seconds: 2)).then((_) async {
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                        builder: (BuildContext context) => super.widget,),);
              } else {
                await buttonController.reverse();
                if (mounted) setState(() {});
              }
            });
          },
        ),
      ],),
    );
  }
}
