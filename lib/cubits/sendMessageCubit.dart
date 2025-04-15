import 'package:customer/repository/chatRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/Model/message.dart';
import 'package:dio/dio.dart';

abstract class SendMessageState {}

class SendMessageInitial extends SendMessageState {}

class SendMessageInProgress extends SendMessageState {}

class SendMessageSuccess extends SendMessageState {
  final Message message;
  SendMessageSuccess({required this.message});
}

class SendMessageFailure extends SendMessageState {
  final String errorMessage;
  SendMessageFailure(this.errorMessage);
}

class SendMessageCubit extends Cubit<SendMessageState> {
  final ChatRepository _chatRepository;
  SendMessageCubit(this._chatRepository) : super(SendMessageInitial());
  Future<void> sendMessage({
    required bool isGroup,
    required String toUserId,
    required String message,
    required List<String> filePaths,
    required String fromId,
  }) async {
    final List<MultipartFile> files = [];
    for (final filePath in filePaths) {
      files.add(await MultipartFile.fromFile(filePath));
    }
    emit(SendMessageInProgress());
    try {
      emit(SendMessageSuccess(
          message: await _chatRepository.sendMessage(parameter: {
        'type': isGroup ? 'group' : 'person',
        'from_id': fromId,
        'to_id': toUserId,
        'message': message,
        'documents': files,
      },),),);
      if (files.isNotEmpty && message.trim().isNotEmpty) {
        emit(SendMessageInProgress());
        emit(SendMessageSuccess(
            message: await _chatRepository.sendMessage(parameter: {
          'type': isGroup ? 'group' : 'person',
          'from_id': fromId,
          'to_id': toUserId,
          'message': message,
        },),),);
      }
    } catch (e) {
      emit(SendMessageFailure(e.toString()));
    }
  }
}
