import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileDownloadHandler {
  /// Creates a unique filename by appending a number if the file already exists
  Future<String> getUniqueFilePath(String fileName) async {
    final Directory directory;
    String filePath;
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
      filePath = path.join(directory.path, fileName);
    } else {
      directory = Directory('/storage/emulated/0/Download');
      filePath = path.join(directory.path, fileName);
    }

    if (!await File(filePath).exists()) {
      return filePath;
    }

    // Split the filename into name and extension
    String name = path.basenameWithoutExtension(fileName);
    String? extension = path.extension(fileName);

    int counter = 1;
    while (true) {
      // Create new filename with counter
      String newFileName = '$name ($counter)$extension';
      String newFilePath = path.join(directory.path, newFileName);

      if (!await File(newFilePath).exists()) {
        return newFilePath;
      }
      counter++;
    }
  }

  /// Downloads a file and handles duplicates
  Future<File> downloadFile(String url, String fileName) async {
    try {
      // Get unique file path
      final filePath = await getUniqueFilePath(fileName);

      // Create http client and make request
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      // Write to file
      final file = File(filePath);
      await response.pipe(file.openWrite());

      return file;
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }
}
