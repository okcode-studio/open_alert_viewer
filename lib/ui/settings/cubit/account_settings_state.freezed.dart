// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AccountSettingsState {
  AlertSourceData? get sourceData => throw _privateConstructorUsedError;
  CheckStatus get status => throw _privateConstructorUsedError;
  String get statusText => throw _privateConstructorUsedError;
  IconType? get statusIcon => throw _privateConstructorUsedError;
  bool get allowClickAccept => throw _privateConstructorUsedError;
  String get acceptButtonText => throw _privateConstructorUsedError;

  /// Create a copy of AccountSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountSettingsStateCopyWith<AccountSettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountSettingsStateCopyWith<$Res> {
  factory $AccountSettingsStateCopyWith(AccountSettingsState value,
          $Res Function(AccountSettingsState) then) =
      _$AccountSettingsStateCopyWithImpl<$Res, AccountSettingsState>;
  @useResult
  $Res call(
      {AlertSourceData? sourceData,
      CheckStatus status,
      String statusText,
      IconType? statusIcon,
      bool allowClickAccept,
      String acceptButtonText});

  $AlertSourceDataCopyWith<$Res>? get sourceData;
}

/// @nodoc
class _$AccountSettingsStateCopyWithImpl<$Res,
        $Val extends AccountSettingsState>
    implements $AccountSettingsStateCopyWith<$Res> {
  _$AccountSettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceData = freezed,
    Object? status = null,
    Object? statusText = null,
    Object? statusIcon = freezed,
    Object? allowClickAccept = null,
    Object? acceptButtonText = null,
  }) {
    return _then(_value.copyWith(
      sourceData: freezed == sourceData
          ? _value.sourceData
          : sourceData // ignore: cast_nullable_to_non_nullable
              as AlertSourceData?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CheckStatus,
      statusText: null == statusText
          ? _value.statusText
          : statusText // ignore: cast_nullable_to_non_nullable
              as String,
      statusIcon: freezed == statusIcon
          ? _value.statusIcon
          : statusIcon // ignore: cast_nullable_to_non_nullable
              as IconType?,
      allowClickAccept: null == allowClickAccept
          ? _value.allowClickAccept
          : allowClickAccept // ignore: cast_nullable_to_non_nullable
              as bool,
      acceptButtonText: null == acceptButtonText
          ? _value.acceptButtonText
          : acceptButtonText // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of AccountSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AlertSourceDataCopyWith<$Res>? get sourceData {
    if (_value.sourceData == null) {
      return null;
    }

    return $AlertSourceDataCopyWith<$Res>(_value.sourceData!, (value) {
      return _then(_value.copyWith(sourceData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AccountSettingsStateImplCopyWith<$Res>
    implements $AccountSettingsStateCopyWith<$Res> {
  factory _$$AccountSettingsStateImplCopyWith(_$AccountSettingsStateImpl value,
          $Res Function(_$AccountSettingsStateImpl) then) =
      __$$AccountSettingsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AlertSourceData? sourceData,
      CheckStatus status,
      String statusText,
      IconType? statusIcon,
      bool allowClickAccept,
      String acceptButtonText});

  @override
  $AlertSourceDataCopyWith<$Res>? get sourceData;
}

/// @nodoc
class __$$AccountSettingsStateImplCopyWithImpl<$Res>
    extends _$AccountSettingsStateCopyWithImpl<$Res, _$AccountSettingsStateImpl>
    implements _$$AccountSettingsStateImplCopyWith<$Res> {
  __$$AccountSettingsStateImplCopyWithImpl(_$AccountSettingsStateImpl _value,
      $Res Function(_$AccountSettingsStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AccountSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceData = freezed,
    Object? status = null,
    Object? statusText = null,
    Object? statusIcon = freezed,
    Object? allowClickAccept = null,
    Object? acceptButtonText = null,
  }) {
    return _then(_$AccountSettingsStateImpl(
      sourceData: freezed == sourceData
          ? _value.sourceData
          : sourceData // ignore: cast_nullable_to_non_nullable
              as AlertSourceData?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CheckStatus,
      statusText: null == statusText
          ? _value.statusText
          : statusText // ignore: cast_nullable_to_non_nullable
              as String,
      statusIcon: freezed == statusIcon
          ? _value.statusIcon
          : statusIcon // ignore: cast_nullable_to_non_nullable
              as IconType?,
      allowClickAccept: null == allowClickAccept
          ? _value.allowClickAccept
          : allowClickAccept // ignore: cast_nullable_to_non_nullable
              as bool,
      acceptButtonText: null == acceptButtonText
          ? _value.acceptButtonText
          : acceptButtonText // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$AccountSettingsStateImpl implements _AccountSettingsState {
  const _$AccountSettingsStateImpl(
      {required this.sourceData,
      required this.status,
      required this.statusText,
      required this.statusIcon,
      required this.allowClickAccept,
      required this.acceptButtonText});

  @override
  final AlertSourceData? sourceData;
  @override
  final CheckStatus status;
  @override
  final String statusText;
  @override
  final IconType? statusIcon;
  @override
  final bool allowClickAccept;
  @override
  final String acceptButtonText;

  @override
  String toString() {
    return 'AccountSettingsState(sourceData: $sourceData, status: $status, statusText: $statusText, statusIcon: $statusIcon, allowClickAccept: $allowClickAccept, acceptButtonText: $acceptButtonText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountSettingsStateImpl &&
            (identical(other.sourceData, sourceData) ||
                other.sourceData == sourceData) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.statusText, statusText) ||
                other.statusText == statusText) &&
            (identical(other.statusIcon, statusIcon) ||
                other.statusIcon == statusIcon) &&
            (identical(other.allowClickAccept, allowClickAccept) ||
                other.allowClickAccept == allowClickAccept) &&
            (identical(other.acceptButtonText, acceptButtonText) ||
                other.acceptButtonText == acceptButtonText));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sourceData, status, statusText,
      statusIcon, allowClickAccept, acceptButtonText);

  /// Create a copy of AccountSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountSettingsStateImplCopyWith<_$AccountSettingsStateImpl>
      get copyWith =>
          __$$AccountSettingsStateImplCopyWithImpl<_$AccountSettingsStateImpl>(
              this, _$identity);
}

abstract class _AccountSettingsState implements AccountSettingsState {
  const factory _AccountSettingsState(
      {required final AlertSourceData? sourceData,
      required final CheckStatus status,
      required final String statusText,
      required final IconType? statusIcon,
      required final bool allowClickAccept,
      required final String acceptButtonText}) = _$AccountSettingsStateImpl;

  @override
  AlertSourceData? get sourceData;
  @override
  CheckStatus get status;
  @override
  String get statusText;
  @override
  IconType? get statusIcon;
  @override
  bool get allowClickAccept;
  @override
  String get acceptButtonText;

  /// Create a copy of AccountSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountSettingsStateImplCopyWith<_$AccountSettingsStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
