import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../model/question_image_selection.dart';

/// question 이미지 선택 실패를 사용자 표시용 메시지로 전달하는 예외입니다.
/// file picker나 이미지 디코더의 원시 오류를 Controller state에 직접 노출하지 않습니다.
/// fields:
/// - [message]: 운영자에게 표시할 안전한 오류 메시지입니다.
class QuestionImagePickerException implements Exception {
  /// 이미지 선택 예외를 생성합니다.
  /// Parameters:
  /// - [message]: 사용자 표시용 오류 메시지입니다.
  /// Returns:
  /// - [instance]: 이미지 선택 실패 예외입니다.
  const QuestionImagePickerException(this.message);

  /// 운영자에게 표시할 안전한 오류 메시지입니다.
  final String message;

  /// 예외를 UI에 표시 가능한 문구로 변환합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 안전한 오류 메시지입니다.
  @override
  String toString() => message;
}

/// question 이미지 파일 선택과 디코딩을 담당하는 service 계약입니다.
/// Controller는 선택 결과만 받아 업로드 service로 넘기고 browser/native picker 세부 구현은 알지 않습니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
abstract class QuestionImagePickerService {
  /// question 이미지 파일을 선택하고 bytes, MIME type, 원본 크기를 반환합니다.
  /// 파일 선택 취소는 오류가 아니라 null 결과로 표현합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 선택된 이미지 정보이거나 사용자가 취소했을 때 null입니다.
  Future<QuestionImageSelection?> pickQuestionImage();
}

/// Flutter Web, mobile, desktop에서 동작하는 image_picker 기반 이미지 선택 service입니다.
/// 선택된 파일 bytes를 읽고 Flutter image codec으로 원본 width/height를 계산합니다.
/// fields:
/// - [_picker]: platform gallery/file picker를 여는 image picker입니다.
/// - [maxSizeBytes]: 허용할 최대 이미지 파일 크기입니다.
class ImagePickerQuestionImagePickerService
    implements QuestionImagePickerService {
  /// image_picker 기반 이미지 선택 service를 생성합니다.
  /// Parameters:
  /// - [picker]: 테스트나 커스텀 실행에서 주입할 image picker입니다.
  /// - [maxSizeBytes]: 선택 가능한 최대 파일 크기입니다.
  /// Returns:
  /// - [instance]: 실제 파일 선택 service입니다.
  ImagePickerQuestionImagePickerService({
    ImagePicker? picker,
    this.maxSizeBytes = 10 * 1024 * 1024,
  }) : _picker = picker ?? ImagePicker();

  /// platform gallery/file picker를 여는 image picker입니다.
  final ImagePicker _picker;

  /// 선택 가능한 최대 파일 크기입니다.
  /// MVP 운영 기준 확정 전까지 10MB를 상한으로 둡니다.
  final int maxSizeBytes;

  /// 사용자가 이미지 파일을 선택하도록 열고 업로드 전 정보를 계산합니다.
  /// web에서는 [PlatformFile.bytes]를 사용하기 위해 withData 옵션을 켭니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 선택 이미지 정보 또는 취소 시 null입니다.
  @override
  Future<QuestionImageSelection?> pickQuestionImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (file == null) {
        return null;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const QuestionImagePickerException('이미지 파일을 읽지 못했습니다.');
      }
      if (bytes.length > maxSizeBytes) {
        throw const QuestionImagePickerException('이미지 용량은 10MB 이하로 업로드해주세요.');
      }

      final contentType = _contentTypeFor(file);
      final dimensions = await _decodeDimensions(bytes);
      return QuestionImageSelection(
        bytes: bytes,
        fileName: _displayNameFor(file),
        contentType: contentType,
        imageWidth: dimensions.width,
        imageHeight: dimensions.height,
      );
    } on QuestionImagePickerException {
      rethrow;
    } on MissingPluginException {
      throw const QuestionImagePickerException(
        '이미지 선택기를 열지 못했습니다. 앱을 새로고침한 뒤 다시 시도해주세요.',
      );
    } on PlatformException catch (_) {
      throw const QuestionImagePickerException('이미지 선택 권한이나 파일을 확인해주세요.');
    }
  }

  String _contentTypeFor(XFile file) {
    final mimeType = file.mimeType?.trim().toLowerCase();
    if (mimeType != null && mimeType.isNotEmpty) {
      final normalized = mimeType == 'image/jpg' ? 'image/jpeg' : mimeType;
      return switch (normalized) {
        'image/jpeg' || 'image/png' || 'image/webp' => normalized,
        _ => throw const QuestionImagePickerException(
          'JPG, PNG, WEBP 이미지만 업로드할 수 있습니다.',
        ),
      };
    }

    final extension = _extensionFromName(_displayNameFor(file)).toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const QuestionImagePickerException(
        'JPG, PNG, WEBP 이미지만 업로드할 수 있습니다.',
      ),
    };
  }

  String _displayNameFor(XFile file) {
    final name = file.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final path = file.path.trim();
    if (path.isEmpty) {
      return 'question-image';
    }
    final slashIndex = path.lastIndexOf(RegExp(r'[/\\]'));
    return slashIndex < 0 ? path : path.substring(slashIndex + 1);
  }

  String _extensionFromName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1);
  }

  Future<_ImageDimensions> _decodeDimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final dimensions = _ImageDimensions(
        width: image.width,
        height: image.height,
      );
      image.dispose();
      if (dimensions.width <= 0 || dimensions.height <= 0) {
        throw const QuestionImagePickerException('이미지 크기를 확인하지 못했습니다.');
      }
      return dimensions;
    } on QuestionImagePickerException {
      rethrow;
    } catch (_) {
      throw const QuestionImagePickerException('지원하지 않는 이미지 파일입니다.');
    }
  }
}

/// 테스트와 mock mode에서 deterministic한 이미지 선택 결과를 제공하는 service입니다.
/// file picker를 열지 않고 Controller upload/save 흐름을 검증할 수 있게 합니다.
/// fields:
/// - [selection]: 반환할 mock 이미지 선택 값입니다.
class MockQuestionImagePickerService implements QuestionImagePickerService {
  /// mock 이미지 선택 service를 생성합니다.
  /// Parameters:
  /// - [selection]: 테스트가 지정할 선택 결과입니다.
  /// Returns:
  /// - [instance]: mock 이미지 선택 service입니다.
  const MockQuestionImagePickerService({
    this.selection = const QuestionImageSelection(
      bytes: <int>[1, 2, 3, 4],
      fileName: 'mock-question.png',
      contentType: 'image/png',
      imageWidth: 900,
      imageHeight: 1200,
    ),
  });

  /// 반환할 mock 이미지 선택 값입니다.
  final QuestionImageSelection? selection;

  /// 미리 지정된 mock 선택 결과를 반환합니다.
  /// null을 주입하면 사용자가 파일 선택을 취소한 흐름을 검증할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: mock 이미지 선택 값이거나 null입니다.
  @override
  Future<QuestionImageSelection?> pickQuestionImage() async => selection;
}

class _ImageDimensions {
  const _ImageDimensions({required this.width, required this.height});

  final int width;
  final int height;
}
