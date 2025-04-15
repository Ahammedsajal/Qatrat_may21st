import 'package:customer/Helper/Constant.dart';
import 'package:customer/Model/Section_Model.dart';
import 'package:customer/Model/groupDetails.dart';
import 'package:customer/Model/personalChatHistory.dart';
import 'package:customer/Screen/Product_DetailNew.dart';
import 'package:customer/Screen/chat/converstationListScreen.dart';
import 'package:customer/Screen/chat/converstationScreen.dart';
import 'package:customer/Screen/chat/searchAdminScreen.dart';
import 'package:customer/cubits/converstationCubit.dart';
import 'package:customer/cubits/searchAdminCubit.dart';
import 'package:customer/cubits/sendMessageCubit.dart';
import 'package:customer/repository/adminDetailsRepository.dart';
import 'package:customer/repository/chatRepository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Routes {
  static navigateToConverstationListScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ConverstationListScreen(
          key: converstationListScreenStateKey,
        ),
      ),
    );
  }

  static navigateToConverstationScreen(
      {required BuildContext context,
      PersonalChatHistory? personalChatHistory,
      GroupDetails? groupDetails,
      required bool isGroup,}) {
    converstationScreenStateKey = GlobalKey<ConverstationScreenState>();
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => ConverstationCubit(ChatRepository()),
                  ),
                  BlocProvider(
                      create: (_) => SendMessageCubit(ChatRepository()),),
                ],
                child: ConverstationScreen(
                    groupDetails: groupDetails,
                    key: converstationScreenStateKey,
                    isGroup: isGroup,
                    personalChatHistory: personalChatHistory,),),),);
  }

  static navigateToSearchSellerScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => SearchAdminCubit(AdminDetailRepository()),
          child: const SearchAdminScreen(),
        ),
      ),
    );
  }

  static Future<void> goToProductDetailsPage(BuildContext context,
      {required Product product,}) async {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ProductDetail(
          id: product.id!,
          list: false,
          index: 0,
          secPos: 0,
        ),
      ),
    );
  }

  static navigateToGroupInfoScreen(
      BuildContext context, GroupDetails groupDetails,) {}
}
