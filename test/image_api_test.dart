import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:test/test.dart';

import 'base_tests.dart';
import 'utils/matchers.dart';

/// ImageAPI tests on each Cloudflare Image API endpoint.
/// These tests ensures that every uploaded test image gets deleted.
void main() async {
  await init();

  test('Handling image from url tests', (){
    expect(CloudinaryImage('https://res.cloudinary.com/test-cloud/image/upload/v1647034940/test-folder/sub-folder/deep-folder/glyoti4j1nzjh0zebpyj.jpg'), ImageMatcher());
    try {
      CloudinaryImage('https://picsum.photos/id/237/536/354');
      fail('Invalid Cloudinary Url exception should be thrown');
    } catch (e) {
      expect(e, InvalidCloudinaryUrlMatcher());
    }
    expect(CloudinaryImage.fromPublicId('some-cloud-name', 'some-public-id'), ImageMatcher());
  });

  group('Upload image tests', () {

    test('Simple signed upload image from file with progress update', () async {
      if (!imageFile.existsSync()) {
        fail('No image file available to upload');
      }
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: imageFile.path,
          folder: folder,
          fileName: 'signed-upload-from-file',
          progressCallback: (count, total) {
            print('Uploading image: ${p.basename(imageFile.path)} from file progress: $count/$total');
          })
      );
      expect(response, ResponseMatcher());
      expect(response.secureUrl, isNotEmpty);
      addSecureUrl(response.secureUrl);
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Simple signed upload image from bytes with progress update', () async {
      if (!imageFile1.existsSync()) {
        fail('No image bytes available to upload');
      }
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          fileBytes: imageFile1.readAsBytesSync(),
          folder: folder,
          fileName: 'signed-upload-from-bytes',
          progressCallback: (count, total) {
            print('Uploading image: ${p.basename(imageFile1.path)} from bytes progress: $count/$total');
          })
      );
      expect(response, ResponseMatcher());
      expect(response.secureUrl, isNotEmpty);
      addSecureUrl(response.secureUrl);
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Multiple upload image from file with progress update', () async {
      if (!imageFile.existsSync() ||
          !imageFile1.existsSync() ||
          !imageFile2.existsSync()) {
        fail(
            'imageFile and imageFile1 and imageFile2 are required for multiple upload test. Check if you set each image file for each env var.');
      }
      final files = [imageFile, imageFile1, imageFile2];
      List<CloudinaryUploadResource> contents = [];
      for (int i = 0; i < files.length; ++i) {
        final file = files[i];
        contents.add(CloudinaryUploadResource(
          filePath: file.path,
          folder: folder,
          fileName: 'signed-multi-upload-from-path-${i + 1}',
          progressCallback: (count, total) {
            print(
              'Multiple upload image from file: ${p.basename(file.path)} progress: $count/$total');
          })
        );
      }
      final responses = await cloudinary.uploadResources(contents,);
      for (final response in responses) {
        expect(response, ResponseMatcher());
      expect(response.secureUrl, isNotEmpty);
        addSecureUrl(response.secureUrl);
      }
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Multiple upload image from bytes with progress update', () async {
      if (!imageFile.existsSync() ||
          !imageFile1.existsSync() ||
          !imageFile2.existsSync()) {
        fail(
            'imageFile and imageFile1 and imageFile2 are required for multiple upload test. Check if you set each image file for each env var.');
      }
      final files = [imageFile, imageFile1, imageFile2];
      List<CloudinaryUploadResource> contents = [];
      for (int i = 0; i < files.length; ++i) {
        final file = files[i];
        contents.add(CloudinaryUploadResource(
          fileBytes: file.readAsBytesSync(),
          folder: folder,
          fileName: 'signed-multi-upload-from-bytes-${i + 1}',
          progressCallback: (count, total) {
            print(
              'Multiple upload image from bytes: ${p.basename(file.path)} progress: $count/$total');
          })
        );
      }
      final responses = await cloudinary.uploadResources(contents,);
      for (final response in responses) {
        expect(response, ResponseMatcher());
      expect(response.secureUrl, isNotEmpty);
        addSecureUrl(response.secureUrl);
      }
    }, timeout: Timeout(Duration(minutes: 2)));


    // group('Image direct upload tests', () {
    //   late final CloudflareHTTPResponse<DataUploadDraft?> response;
    //   late final DataUploadDraft? dataUploadDraft;
    //
    //   setUpAll(() async {
    //     response = await cloudinary.imageAPI.createDirectUpload();
    //     dataUploadDraft = response.body;
    //   });
    //
    //   test('Create authenticated direct image upload URL', () async {
    //     expect(response, ResponseMatcher());
    //     expect(response.secureUrl, isNotEmpty);
    //     expect(dataUploadDraft?.id, isNotEmpty);
    //     expect(dataUploadDraft?.uploadURL, isNotEmpty);
    //   });
    //
    //   test('Check created image draft status', () async {
    //     if (dataUploadDraft?.id.isEmpty ?? true) {
    //       fail('No secureUrl available to check draft status');
    //     }
    //     final response = await cloudinary.imageAPI.get(id: dataUploadDraft?.id);
    //     expect(response, ImageMatcher());
    //     expect(response.body?.draft, true);
    //   }, timeout: Timeout(Duration(minutes: 2)));
    //
    //   test('Doing image upload to direct upload URL', () async {
    //     if (dataUploadDraft?.uploadURL.isEmpty ?? true) {
    //       fail('No uploadURL available to upload to');
    //     }
    //     final response = await cloudinary.imageAPI.directUpload(
    //       dataUploadDraft: dataUploadDraft!,
    //       contentFromFile: DataTransmit<File>(
    //         data: imageFile,
    //         progressCallback: (count, total) {
    //           print('Image upload to direct upload URL from file progress: $count/$total');
    //         })
    //     );
    //     expect(response, ImageMatcher());
    //     addId(response.body?.id);
    //     expect(response.body?.id, dataUploadDraft?.id);
    //     expect(response.body?.draft, false);
    //   }, timeout: Timeout(Duration(minutes: 2)));
    // });
  });

  group('Delete resources tests', () {
    test('Delete resource from publicId test', () async {
      final secureUrl = cacheUrls.isNotEmpty ? cacheUrls.first : null;
      if (secureUrl == null) {
        fail('No resource available to delete');
      }

      final response = await cloudinary.deleteResource(
        publicId: CloudinaryImage(secureUrl).publicId,
      );
      expect(response, ResponseMatcher());
      cacheUrls.remove(secureUrl);
    });

    test('Delete resource from url test', () async {
      final secureUrl = cacheUrls.isNotEmpty ? cacheUrls.first : null;
      if (secureUrl == null) {
        fail('No resource available to delete');
      }

      final response = await cloudinary.deleteResource(
        url: secureUrl,
      );
      expect(response, ResponseMatcher());
      cacheUrls.remove(secureUrl);
    });

    test('Delete resource from CloudinaryImage test', () async {
      final secureUrl = cacheUrls.isNotEmpty ? cacheUrls.first : null;
      if (secureUrl == null) {
        fail('No resource available to delete');
      }

      final response = await cloudinary.deleteResource(
        cloudinaryImage: CloudinaryImage(secureUrl),
      );
      expect(response, ResponseMatcher());
      cacheUrls.remove(secureUrl);
    });

    test('Delete multiple images', () async {
      if (cacheUrls.isEmpty) {
        fail('There are no uploaded images to test multi delete.');
      }

      final response = await cloudinary.deleteResources(
        urls: cacheUrls.toList(),
      );
      expect(response, ResponseMatcher());
      print('Deleted: ${cacheUrls.length} of ${cacheUrls.length}');
    }, timeout: Timeout(Duration(minutes: 10)));
  });
}
