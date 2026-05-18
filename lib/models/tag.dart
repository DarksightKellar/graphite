import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';

@freezed
class Tag with _$Tag {
  @JsonKey(name: 'id')
  final String id;
  
  final int noteCount; // how many notes reference this tag
  
  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
