import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'customer_api_service.g.dart';

@riverpod
CustomerApiService customerApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return CustomerApiService(dio);
}

class CustomerApiService {
  final Dio _dio;

  CustomerApiService(this._dio);

  Future<List<Map<String, dynamic>>> searchCustomers({required String query, int limit = 10}) async {
    final response = await _dio.get(
      ApiEndpoints.customersSearch,
      queryParameters: {
        'q': query,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiEndpoints.customers,
      data: data,
    );
    final resData = response.data;
    if (resData is Map && resData['data'] is Map) {
      return resData['data'] as Map<String, dynamic>;
    }
    return resData;
  }
}
