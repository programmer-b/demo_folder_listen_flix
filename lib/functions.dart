import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:demo_folder_listen_flix/strings.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<void> downloadInfo(
    {required String backdropUrl,
    required String posterUrl,
    required String query,
    required String year,
    required String type,
    required String homeUrl,
    required String? logoUrl}) async {
  final filename = query.getFolderName();
  final lPath = (await getApplicationDocumentsDirectory()).path;

  final bool exists = await Directory(
          "$lPath/$kfAppParentDir/${type == 'movie' ? "Movie" : "TV"}/$filename")
      .exists();
  if (!exists) {
    try {
      final backDir = await localPath(
          path: "${type == 'movie' ? "Movie" : "TV"}/$filename/$backdropPath");
      log("DOWNLOADING BACKDROP $backdropUrl");
      await _storeImage(
          await _downloadImage("$kfOriginalTMDBImageUrl$backdropUrl"),
          path: "$backDir/${basename(backdropUrl)}");

      final logoDir = await localPath(
          path: "${type == 'movie' ? "Movie" : "TV"}/$filename/$logoPath");

      if (logoUrl != null) {
        log("DOWNLOADING LOGO $logoUrl");
        await _storeImage(
            await _downloadImage("$kfOriginalTMDBImageUrl$logoUrl"),
            path: "$logoDir/${basename(logoUrl)}");
      } else {
        log("LOGO URL IS NULL");
      }

      final infoDir = await localPath(
          path: "${type == 'movie' ? "Movie" : "TV"}/$filename/$infoPath");

      final List<Map<String, String>> info = [
        {"key": "$infoDir/query", "value": query},
        {"key": "$infoDir/year", "value": year},
        {"key": "$infoDir/type", "value": type},
        {"key": "$infoDir/homeUrl", "value": homeUrl}
      ];

      log("\n\nDOWNLOADING STRINGS: $info \n\n");
      for (var path in info) {
        await _storeString(
            path: "${path["key"]}.txt",
            value: "$infoDir/${path["value"] ?? ""}");
      }
    } catch (exception) {
      _deleteFile(filename);
      rethrow;
    }
  } else {
    log("Info on $filename aleady exists");
    return;
  }
}

Future<Uint8List> _downloadImage(String url) async {
  final response = await http.get(Uri.parse(url));
  final bytes = response.bodyBytes;
  return bytes;
}

Future<File> _storeImage(List<int> bytes, {required String path}) async {
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<File> _storeString({required String path, required String value}) async {
  final file = File(path);
  await file.writeAsString(value, flush: true);

  return file;
}

Future<void> _deleteFile(String path) async {
  bool exists = await directoryExists(filename: path);
  if (exists) {
    Directory(path).delete();
  }
  return;
}

Future<bool> directoryExists({required String filename}) async {
  final pathName = await localPath(path: filename);

  bool fileExists = await File("$pathName/$filename").exists();
  bool exists = fileExists;
  return exists;
}

Stream<List<FileSystemEntity>> fileStream(Directory directory,
    {bool changeCurrentPath = true,
    bool reverse = false,
    bool recursive = false,
    bool keepHidden = false}) async* {
  var dir = directory;
  var files = <FileSystemEntity>[];
  try {
    if (dir.listSync(recursive: recursive).isNotEmpty) {
      if (!keepHidden) {
        yield* dir.list(recursive: recursive).transform(
            StreamTransformer.fromHandlers(
                handleData: (FileSystemEntity data, sink) {
          files.add(data);
          sink.add(files);
        }));
      } else {
        yield* dir.list(recursive: recursive).transform(
            StreamTransformer.fromHandlers(
                handleData: (FileSystemEntity data, sink) {
          if (basename("$data").startsWith('.')) {
            files.add(data);
            sink.add(files);
          }
        }));
      }
    } else {
      yield [];
    }
  } on FileSystemException catch (e) {
    log("$e");
    yield [];
  }
}

Iterable<Map<String, String>> allPopularData(Map<String, String>? snapshot) {
  log("Has data");
  final data = snapshot;

  final movies = parse(data?["movies"]);
  final tvs = parse(data?["tvs"]);

  final List moviesData = movies.getData();
  final List tvsData = tvs.getData();

  final List<Map<String, String>> moviesPopularData = List.generate(
      moviesData.length,
      (index) => {
            "query": moviesData.getQuery(index),
            "year": moviesData.getYear(index),
            "type": "movie",
            "homeUrl": moviesData.getHomeUrl(index)
          });
  final List<Map<String, String>> tvsPopularData = List.generate(
      tvsData.length,
      (index) => {
            "query": tvsData.getQuery(index),
            "year": tvsData.getYear(index),
            "type": "tv",
            "homeUrl": moviesData.getHomeUrl(index)
          });

  return zip(
      moviesPopularData: moviesPopularData, tvsPopularData: tvsPopularData);
}

Future<String> localPath({String path = ''}) async {
  final Directory appDocDir = await getApplicationDocumentsDirectory();

  final Directory appDocDirFolder = Directory(
      "${appDocDir.path}/$kfAppParentDir${path == '' ? "" : "/$path"}");

  if (await appDocDirFolder.exists()) {
    return appDocDirFolder.path;
  } else {
    final Directory appDocDirNewFolder =
        await appDocDirFolder.create(recursive: true);
    return appDocDirNewFolder.path;
  }
}

Iterable<Map<String, String>> zip<T>(
    {required List<Map<String, String>> moviesPopularData,
    required List<Map<String, String>> tvsPopularData}) sync* {
  final ita = moviesPopularData.iterator;
  final itb = tvsPopularData.iterator;
  bool hasa, hasb;
  while ((hasa = ita.moveNext()) | (hasb = itb.moveNext())) {
    if (hasa) yield ita.current;
    if (hasb) yield itb.current;
  }
}

Future<Response> getDataFromInternet({required String url}) async {
  try {
    return await http.get(Uri.parse(url));
  } on Exception catch (e) {
    log("$e");
    rethrow;
  }
}

Future<Map<String, String>> extractImageInformation(
    {required List<FileSystemEntity> dir}) async {
  try {
    final baseImagePath = dir[0].path;
    final baseStringPath = dir[1].path;

    var backdropImagePath = Directory("$baseImagePath/backdrops/").path;
    var posterImagePath = Directory("$baseImagePath/logos/").path;

    var backDContents = Directory(backdropImagePath).listSync()[0].path;
    var logoContents = Directory(posterImagePath).listSync()[0].path;

    final String year = await File("$baseStringPath/year.txt").readAsString();
    final String query = await File("$baseStringPath/query.txt").readAsString();
    final String type = await File("$baseStringPath/type.txt").readAsString();
    final String homeUrl =
        await File("$baseStringPath/homeUrl.txt").readAsString();

    return {
      "backdrop_image": backDContents,
      "logo_image": logoContents,
      "year": year.getFileName(),
      "query": query.getFileName(),
      "type": type.getFileName(),
      "homeUrl": homeUrl.getFileName(),
    };
  } on Exception catch (e) {
    rethrow;
  }
}

extension GetQuery on List {
  String getQuery(index) {
    return this[index].getElementsByClassName('mtl')[0].innerHtml;
  }
}

extension GetYear on List {
  String getYear(index) {
    return this[index].getElementsByClassName('hd hdy')[0].innerHtml;
  }
}

extension GetHomeUrl on List {
  String getHomeUrl(index) {
    return this[index].getElementsByTagName('a')[0].attributes['href'];
  }
}

extension GetData on Document {
  List getData() {
    return getElementsByClassName('dflex')[1].children;
  }
}

extension ParentName on String {
  String parentName() {
    return substring(0, indexOf("."));
  }
}

extension GetFolderName on String {
  String getFolderName() {
    return replaceAll("'", "").replaceAll(" ", "").trim();
  }
}

extension GetFileName on String {
  String getFileName() {
    return this.split('/').last;
  }
}
