import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/branch_option.dart';
import '../../services/branch_api_service.dart';
import 'branch_repository.dart';

/// Concrete implementation of [BranchRepository].
class BranchRepositoryImpl implements BranchRepository {
  final BranchApiService _apiService;

  BranchRepositoryImpl(this._apiService);

  @override
  Future<List<BranchOption>> getBranches() async {
    try {
      final raw = await _apiService.getBranches();
      return raw.map(BranchOption.fromJson).toList();
    } on DioException catch (e) {
      developer.log(
        '❌ [BranchRepository] getBranches FAILED! Error data: ${e.response?.data} | Exception: $e',
      );
      throw ApiException(
        message: e.message ?? 'Lỗi kết nối máy chủ',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
