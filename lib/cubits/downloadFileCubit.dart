import 'dart:io';
import 'package:dio/dio.dart';
import 'package:customer/Helper/Constant.dart';
import 'package:customer/repository/downloadRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DownloadFileState {}

class DownloadFileInitial extends DownloadFileState {}

class DownloadFileInProgress extends DownloadFileState {
  final double downloadPercentage;
  DownloadFileInProgress(this.downloadPercentage);
}

class DownloadFileSuccess extends DownloadFileState {
  final String downloadedFileUrl;
  DownloadFileSuccess(this.downloadedFileUrl);
}

class DownloadFileProcessCanceled extends DownloadFileState {}

class DownloadFileFailure extends DownloadFileState {
  final String errorMessage;
  DownloadFileFailure(this.errorMessage);
}

class DownloadFileCubit extends Cubit<DownloadFileState> {
  final DownloadRepository _downloadRepository;
  DownloadFileCubit(this._downloadRepository) : super(DownloadFileInitial());
  final CancelToken _cancelToken = CancelToken();
  void _downloadedFilePercentage(double percentage) {
    emit(DownloadFileInProgress(percentage));
  }

  Future<void> writeFileFromTempStorage(
      {required String sourcePath, required String destinationPath,}) async {
    final tempFile = File(sourcePath);
    final byteData = await tempFile.readAsBytes();
    final downloadedFile = File(destinationPath);
    await downloadedFile.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),);
  }

  Future<void> downloadFile(
      {required String fileUrl,
      required String fileName,
      required String fileExtension,
      required bool storeInExternalStorage,}) async {
    emit(DownloadFileInProgress(0.0));
    try {
      if (storeInExternalStorage) {
        if (await hasStoragePermissionGiven()) {
          final tempPath = await getTempStoragePath();
          final tempFileSavePath = '$tempPath/$fileName.$fileExtension';
          await _downloadRepository.downloadFile(
              cancelToken: _cancelToken,
              savePath: tempFileSavePath,
              updateDownloadedPercentage: _downloadedFilePercentage,
              url: fileUrl,);
          String downloadFilePath = await getExternalStoragePath();
          downloadFilePath = '$downloadFilePath/$fileName.$fileExtension';
          print("downloadpath-->$downloadFilePath");
          await writeFileFromTempStorage(
              sourcePath: tempFileSavePath, destinationPath: downloadFilePath,);
          emit(DownloadFileSuccess(downloadFilePath));
        } else {
          emit(DownloadFileFailure('Please give storage permission'));
        }
      } else {
        final tempPath = await getTempStoragePath();
        final savePath = '$tempPath/$fileName.$fileExtension';
        await _downloadRepository.downloadFile(
            cancelToken: _cancelToken,
            savePath: savePath,
            updateDownloadedPercentage: _downloadedFilePercentage,
            url: fileUrl,);
        emit(DownloadFileSuccess(savePath));
      }
    } catch (e) {
      if (_cancelToken.isCancelled) {
        emit(DownloadFileProcessCanceled());
      } else {
        emit(DownloadFileFailure(e.toString()));
      }
    }
  }

  void cancelDownloadProcess() {
    _cancelToken.cancel();
  }
}
