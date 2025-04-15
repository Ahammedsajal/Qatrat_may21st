import 'package:flutter_bloc/flutter_bloc.dart';
import '../Model/MosqueModel.dart';
import '../Helper/ApiBaseHelper.dart';
import '../Helper/Session.dart'; // Handles authentication
import '../settings.dart';

/// States for Fetching Mosques
abstract class FetchMosquesState {}

class FetchMosquesInitial extends FetchMosquesState {}

class FetchMosquesInProgress extends FetchMosquesState {}

class FetchMosquesSuccess extends FetchMosquesState {
  final List<MosqueModel> mosques;
  FetchMosquesSuccess(this.mosques);
}

class FetchMosquesFail extends FetchMosquesState {
  final String error;
  FetchMosquesFail(this.error);
}

/// Cubit Class
class FetchMosquesCubit extends Cubit<FetchMosquesState> {
  final ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  FetchMosquesCubit() : super(FetchMosquesInitial());

  Future<void> fetchMosques({String? userId}) async {
    emit(FetchMosquesInProgress());

    // Fetch userId from session if not provided
    userId ??= getToken();
final effectiveUserId = userId.isNotEmpty ? userId : "0";
    
    try {
      final Uri url = Uri.parse("${AppSettings.baseUrl}get_mosques");
      final Map<String, String> parameters = {"user_id": userId};

      final response = await apiBaseHelper.postAPICall(url, parameters);

      // Check for API response errors
      if (_hasError(response)) return;

      final List<MosqueModel> mosqueList = (response["data"] as List)
          .map((data) => MosqueModel.fromJson(data))
          .toList();

      if (mosqueList.isEmpty) {
        emit(FetchMosquesFail("No mosques found."));
      } else {
        emit(FetchMosquesSuccess(mosqueList));
      }
    } catch (e) {
      emit(FetchMosquesFail("Failed to fetch mosques: ${e.toString()}"));
    }
  }

  /// Error checking method to match `FetchFeaturedSectionsCubit`
  bool _hasError(dynamic response) {
    if (response['error'] == true) {
      emit(FetchMosquesFail(response['message'] ?? "An error occurred."));
      return true;
    }
    return false;
  }
}
