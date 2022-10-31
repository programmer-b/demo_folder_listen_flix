import 'dart:convert';
import 'dart:developer';

import 'package:demo_folder_listen_flix/functions.dart';
import 'package:demo_folder_listen_flix/strings.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Future<Map<String, String>> data;

  Future<Map<String, String>> _getPopularData() async {
    final popularMovies = await getDataFromInternet(url: movies);
    final popularTvs = await getDataFromInternet(url: tvs);

    return {"movies": popularMovies.body, "tvs": popularTvs.body};
  }

  Future<void> _downloadImages(
      Iterable<Map<String, String>> popularData) async {
    List<Map<String, String>> data = [];
    for (var i in popularData) {
      data.add(i);
    }

    // data = List.from(data.reversed);

    int position = 0;

    for (var element in data) {
      if (position == 9) break;

      final String query = element["query"] ?? "";
      final String year = element["year"] ?? "";
      String type = element["type"] ?? "";
      final String homeUrl = element["homeUrl"] ?? "";

      Map<String, dynamic> dataMap = {"results": []};

      int i = 0;

      while (dataMap["results"].isEmpty && i < 2) {
        final url =
            kfTMDBSearchMoviesORSeriesUrl(type: type, year: year, query: query);

        final searchedData = await getDataFromInternet(url: url);

        final List results = jsonDecode(searchedData.body)["results"];
        if (results.isEmpty) {
          log("searched for $query but found no results \n changing type now from $type");
          type == "movie" ? type = "tv" : type = "movie";
          log("current type is $type");
          i++;
        } else {
          log("did find $query");
          dataMap["results"] = results;
        }
      }

      final id = dataMap["results"][0]["id"];

      final searchedImages = await getDataFromInternet(
          url: kfTMDBSearchImagesUrl(type: type, id: "$id"));

      final backdropUrl = dataMap["results"][0]["backdrop_path"] ??
          dataMap["results"][0]["poster_path"] ??
          "";
      List logos = jsonDecode(searchedImages.body)?["logos"];
      String? logoUrl;

      if (logos.isNotEmpty) {
        logoUrl = logos[0]?["file_path"] ?? "";
        if (logoUrl == "") logoUrl = null;
      } else {
        logoUrl = null;
      }

      if (logoUrl == null) continue;

      final posterUrl = dataMap["results"][0]["poster_path"] ?? "";

      await downloadInfo(
          backdropUrl: backdropUrl,
          posterUrl: posterUrl,
          query: query,
          year: year,
          type: type,
          homeUrl: homeUrl,
          logoUrl: logoUrl);

      if (position == 1) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) =>
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(data: popularData))));
      }

      position++;
    }
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    data = _getPopularData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
        future: data,
        builder: (context, AsyncSnapshot<Map<String, String>> snapshot) {
          if (snapshot.hasData) {
            final data = allPopularData(snapshot.data);
            _downloadImages(data);
          }
          if (snapshot.hasError) {
            return _error("${snapshot.error}");
          }
          return _loadingIndicator();
        });
  }

  Widget _loadingIndicator() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );

  Widget _error(String error) => Scaffold(
        body: Center(
          child: Text(error),
        ),
      );
}
