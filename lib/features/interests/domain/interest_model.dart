import 'package:freezed_annotation/freezed_annotation.dart';

part 'interest_model.freezed.dart';
part 'interest_model.g.dart';

@freezed
class InterestModel with _$InterestModel {
  const factory InterestModel({
    int? id,
    required String name,
    required String emoji,
  }) = _InterestModel;

  factory InterestModel.fromJson(Map<String, dynamic> json) => 
      _$InterestModelFromJson(json);
}