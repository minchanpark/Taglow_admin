class ImageRatioReader {
  const ImageRatioReader();

  double fromDimensions({required int width, required int height}) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Image width and height must be greater than zero.');
    }
    return width / height;
  }
}
