import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lumara_scan/services/document_scanner_service.dart';
import 'package:image_picker/image_picker.dart';
import 'Classes.dart';
import 'database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class FileOperations {
  final String appName = 'OpenScan';
  DatabaseHelper database = DatabaseHelper();

  Future<String> getAppPath() async {
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$appName/');

    if (await _appDocDirFolder.exists()) {
      return _appDocDirFolder.path;
    } else {
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  /// Create new PDF
  Future<bool> createPdf(
      {selectedDirectory, fileName, required List<File> images}) async {
    try {
      final output = File("${selectedDirectory.path}/$fileName.pdf");

      int i = 0;

      final doc = pw.Document();

      for (i = 0; i < images.length; i++) {
        final image = pw.MemoryImage(images[i].readAsBytesSync());
        doc.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image),
              );
            },
            margin: pw.EdgeInsets.all(2.0),
          ),
        );
      }

      output.writeAsBytesSync(await doc.save());
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // ADD IMAGES
  Future<File?> openCamera() async {
    File? image;
    try {
      var picture = await ImagePicker().pickImage(source: ImageSource.camera);
      if (picture != null) {
        image = File(picture.path);
        print('📸 Image captured: ${picture.path}');

        // ✅ CROP IMAGE AUTOMATICALLY after capture (OPTIONAL - won't crash if fails)
        try {
          print('🔄 Attempting to open cropper...');
          final scanner = DocumentScannerService();
          final croppedPath = await scanner.cropImage(picture.path);

          if (croppedPath != null && croppedPath.isNotEmpty) {
            // Verify cropped file exists
            if (await File(croppedPath).exists()) {
              image = File(croppedPath);
              print('✅ Image cropped successfully: $croppedPath');
            } else {
              print('⚠️ Cropped file does not exist, using original');
            }
          } else {
            print('⚠️ Cropping cancelled by user, using original image');
          }
        } catch (cropError, stackTrace) {
          print('❌ Cropping error: $cropError');
          print('Stack trace: $stackTrace');
          print('✅ Falling back to original image - app will NOT crash');
          // Continue with original image - DO NOT crash
        }
      }
    } catch (cameraError, stackTrace) {
      print('❌ Camera error: $cameraError');
      print('Stack trace: $stackTrace');
      return null;
    }

    return image;
  }

  Future<List<File>> openGallery() async {
    List<XFile> pic = [];
    try {
      pic = await ImagePicker().pickMultiImage();
      print('📂 Gallery images selected: ${pic.length}');
    } catch (e, stackTrace) {
      print('❌ Gallery picker error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }

    List<File> imageFiles = [];

    for (int i = 0; i < pic.length; i++) {
      XFile image = pic[i];
      print('Processing gallery image ${i + 1}/${pic.length}: ${image.path}');

      // ✅ CROP EACH IMAGE from gallery (OPTIONAL - won't crash if fails)
      try {
        final scanner = DocumentScannerService();
        final croppedPath = await scanner.cropImage(image.path);

        if (croppedPath != null && croppedPath.isNotEmpty) {
          // Verify cropped file exists
          if (await File(croppedPath).exists()) {
            imageFiles.add(File(croppedPath));
            print('✅ Gallery image ${i + 1} cropped: $croppedPath');
          } else {
            imageFiles.add(File(image.path));
            print('⚠️ Cropped file missing, using original for image ${i + 1}');
          }
        } else {
          imageFiles.add(File(image.path));
          print('⚠️ Cropping cancelled for image ${i + 1}, using original');
        }
      } catch (cropError, stackTrace) {
        print('❌ Cropping error for gallery image ${i + 1}: $cropError');
        print('Stack trace: $stackTrace');
        imageFiles.add(File(image.path));
        print('✅ Using original image ${i + 1} - app will NOT crash');
      }
    }

    return imageFiles;
  }

  Future<void> saveImage(
      {required File image,
      required int index,
      required String dirPath}) async {
    if (!await Directory(dirPath).exists()) {
      new Directory(dirPath).create();
      await database.createDirectory(
        directory: DirectoryOS(
          dirName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
          dirPath: dirPath,
          imageCount: 0,
          created: DateTime.parse(dirPath
              .substring(dirPath.lastIndexOf('/') + 1)
              .substring(
                  dirPath.substring(dirPath.lastIndexOf('/') + 1).indexOf(' ') +
                      1)),
          newName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
          lastModified: DateTime.parse(dirPath
              .substring(dirPath.lastIndexOf('/') + 1)
              .substring(
                  dirPath.substring(dirPath.lastIndexOf('/') + 1).indexOf(' ') +
                      1)),
        ),
      );
    }

    // Removed Index in image path
    File tempPic = File("$dirPath/${DateTime.now()}.jpg");
    image.copy(tempPic.path);
    database.createImage(
      image: ImageOS(
        imgPath: tempPic.path,
        idx: index,
      ),
      tableName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
    );
    if (index == 1) {
      database.updateFirstImagePath(imagePath: tempPic.path, dirPath: dirPath);
    }
  }

  // SAVE TO DEVICE
  Future<Directory?> pickDirectory(
      BuildContext context, selectedDirectory) async {
    Directory? directory = selectedDirectory;
    try {
      if (Platform.isAndroid) {
        directory = Directory("/storage/emulated/0/Documents/");
      } else {
        directory = await getExternalStorageDirectory();
      }
    } catch (e) {
      print(e);
      directory = await getExternalStorageDirectory();
    }

    return directory;
  }

  Future<String?> saveToDevice({
    required BuildContext context,
    required String fileName,
    required List<ImageOS> images,
    required int quality,
  }) async {
    Directory? selectedDirectory;
    Directory openscanDir = Directory("/storage/emulated/0/Documents/OpenScan");
    Directory openscanPdfDir =
        Directory("/storage/emulated/0/Documents/OpenScan/PDF");
    int desiredQuality = 100;

    try {
      if (!openscanDir.existsSync()) {
        openscanDir.createSync();
      }
      if (!openscanPdfDir.existsSync()) {
        openscanPdfDir.createSync();
      }
      selectedDirectory = openscanPdfDir;
    } catch (e) {
      print(e);
      selectedDirectory = await pickDirectory(context, selectedDirectory);
    }

    List<File> imageFiles = [];
    String path;

    if (quality == 1) {
      desiredQuality = 20;
    } else if (quality == 2) {
      desiredQuality = 60;
    } else if (quality == 3) {
      desiredQuality = 100;
    } else {
      desiredQuality = 50;
    }

    print(desiredQuality);

    final scannerService = DocumentScannerService();
    for (ImageOS image in images) {
      path = await scannerService.compressImage(image.imgPath, quality: desiredQuality);
      imageFiles.add(File(path));
    }

    fileName = fileName.replaceAll('-', '');
    fileName = fileName.replaceAll('.', '');
    fileName = fileName.replaceAll(':', '');

    bool pdfStatus = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: imageFiles,
    );
    return (pdfStatus) ? selectedDirectory?.path : null;
  }

  Future<bool> saveToAppDirectory(
      {required String fileName, required List<ImageOS> images}) async {
    Directory selectedDirectory = await getApplicationDocumentsDirectory();

    List<ImageOS> imageOSList = [];
    List<File> imageFiles = [];

    if (images.runtimeType == imageOSList.runtimeType) {
      for (ImageOS image in images) {
        imageFiles.add(File(image.imgPath));
      }
    }

    bool pdfStatus = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: imageFiles,
    );
    return pdfStatus;
  }

  /// Delete the temporary files created by the image_picker package
  Future<void> deleteTemporaryFiles() async {
    Directory? appDocDir = await getExternalStorageDirectory();
    Directory cacheDir = await getTemporaryDirectory();
    String appDocPath = "${appDocDir?.path}/Pictures/";
    Directory del = Directory(appDocPath);
    if (del.existsSync()) {
      del.deleteSync(recursive: true);
    }
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
    new Directory(appDocPath).create();
  }
}
