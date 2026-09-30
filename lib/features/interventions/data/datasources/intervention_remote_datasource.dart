import 'package:dio/dio.dart';

import '../../../../core/network/dio_error_mapper.dart';
import '../models/intervention_model.dart';

class InterventionRemoteDataSource {
  final Dio _dio;
  InterventionRemoteDataSource(this._dio);

  Future<List<InterventionModel>> fetchAll() async {
    try {
      final res = await _dio.get('/interventions');
      final list = res.data as List;
      return list
          .map((e) => InterventionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<InterventionModel> fetchById(String id) async {
    try {
      final res = await _dio.get('/interventions/$id');
      return InterventionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Envoie une intervention au serveur :
  /// PUT si elle existe déjà, sinon POST (création).
  /// Rejouer deux fois la même action ne crée donc pas de doublon.
  Future<void> push(InterventionModel model) async {
    try {
      await _dio.put('/interventions/${model.id}', data: model.toJson());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          await _dio.post('/interventions', data: model.toJson());
          return;
        } on DioException catch (e2) {
          throw mapDioException(e2);
        }
      }
      throw mapDioException(e);
    }
  }
}