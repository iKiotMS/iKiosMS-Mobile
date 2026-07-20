import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'order_api_service.g.dart';

@riverpod
OrderApiService orderApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return OrderApiService(dio);
}

class OrderApiService {
  final Dio _dio;

  OrderApiService(this._dio);

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiEndpoints.orders,
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrders(Map<String, dynamic> params) async {
    final response = await _dio.get(
      ApiEndpoints.orders,
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }
}
