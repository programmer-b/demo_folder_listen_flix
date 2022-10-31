import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:demo_folder_listen_flix/functions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart' hide log;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.data}) : super(key: key);
  final Iterable<Map<String, String>> data;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Iterable<Map<String, String>> data = widget.data;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: FutureBuilder<String>(
          future: localPath(),
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.connectionState == ConnectionState.done) {
              final dir = Directory(snapshot.data ?? "");
              return Scaffold(
                  appBar: AppBar(
                    title: const Text("Home page"),
                    bottom: const TabBar(labelColor: Colors.white, tabs: [
                      Tab(text: "Movies"),
                      Tab(
                        text: "Tv Shows",
                      )
                    ]),
                  ),
                  body: TabBarView(
                    children: [
                      BuildMoviesScreen(directory: dir),
                      BuildTvsScreen(directory: dir)
                    ],
                  ));
            }
            return snapWidgetHelper(snapshot);
          }),
    );
  }
}

class BuildMoviesScreen extends StatelessWidget {
  const BuildMoviesScreen({Key? key, required this.directory})
      : super(key: key);
  final Directory directory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [BuildMoviesCarousel(directory: directory)],
    );
  }
}

class BuildTvsScreen extends StatelessWidget {
  const BuildTvsScreen({Key? key, required this.directory}) : super(key: key);
  final Directory directory;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [BuildTVsCarousel(directory: directory)],
    );
  }
}

class BuildMoviesCarousel extends StatelessWidget {
  const BuildMoviesCarousel({Key? key, required this.directory})
      : super(key: key);
  final Directory directory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
        stream: Directory("${directory.path}/Movie").watch(),
        builder: (context, snapshot) {
          return MoviesCarousel(
              directory: Directory("${directory.path}/Movie"));
        });
  }
}

class BuildTVsCarousel extends StatelessWidget {
  const BuildTVsCarousel({Key? key, required this.directory}) : super(key: key);

  final Directory directory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
        stream: Directory("${directory.path}/TV").watch(),
        builder: (context, snapshot) {
          return TVShowsCarousel(directory: Directory("${directory.path}/TV"));
        });
  }
}

class MoviesCarousel extends StatefulWidget {
  const MoviesCarousel({Key? key, required this.directory}) : super(key: key);
  final Directory directory;

  @override
  State<MoviesCarousel> createState() => _MoviesCarouselState();
}

class _MoviesCarouselState extends State<MoviesCarousel> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FileSystemEntity>>(
        stream: fileStream(widget.directory),
        initialData: const [],
        builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
          return BuildCarouselImage(snapshot: snapshot);
        });
  }
}

class TVShowsCarousel extends StatefulWidget {
  const TVShowsCarousel({Key? key, required this.directory}) : super(key: key);
  final Directory directory;

  @override
  State<TVShowsCarousel> createState() => _TVShowsCarousel();
}

class _TVShowsCarousel extends State<TVShowsCarousel> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FileSystemEntity>>(
        stream: fileStream(widget.directory),
        initialData: const [],
        builder: (context, snapshot) {
          return BuildCarouselImage(
            snapshot: snapshot,
          );
        });
  }
}

class BuildCarouselImage extends StatefulWidget {
  const BuildCarouselImage({Key? key, required this.snapshot})
      : super(key: key);
  final AsyncSnapshot<List<FileSystemEntity>> snapshot;

  @override
  State<BuildCarouselImage> createState() => _BuildCarouselImageState();
}

class _BuildCarouselImageState extends State<BuildCarouselImage> {
  int activeIndex = 0;
  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * 0.3;
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.snapshot.data?.length ?? 0,
          itemBuilder: (context, index, realIndex) => widget
                      .snapshot.data?.isNotEmpty ??
                  false
              ? Builder(builder: (context) {
                  var dir = Directory("${widget.snapshot.data?[index].path}")
                      .listSync();
                  return dir.length > 1
                      ? FutureBuilder<Map<String, String>>(
                          future: extractImageInformation(dir: dir),
                          builder: (context, snapshot) {
                            if (snapshot.data?.isNotEmpty ?? false) {
                              return Builder(builder: (context) {
                                final data = snapshot.data ?? {};

                                return data.isNotEmpty
                                    ? Stack(
                                        children: [
                                          Image.file(
                                            File(data["backdrop_image"] ?? ""),
                                            fit: BoxFit.fill,
                                            height: height,
                                          ),
                                          Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 100,
                                                width: double.infinity,
                                                padding: const EdgeInsets.only(
                                                    left: 4,
                                                    right: 4,
                                                    bottom: 5),
                                                child: Image.file(File(
                                                    data["logo_image"] ?? "")),
                                              ))
                                        ],
                                      )
                                    : Container();
                              });
                            }
                            return snapWidgetHelper(snapshot);
                          })
                      : Container();
                })
              : Container(),
          options: CarouselOptions(
            viewportFraction: 1,
            height: height,
            autoPlay: widget.snapshot.data!.length > 8,
            onPageChanged: (index, reason) =>
                setState(() => activeIndex = index),
          ),
        ),
        3.height,
        BuildCarouselIndicator(
            activeIndex: activeIndex, count: widget.snapshot.data?.length ?? 0)
      ],
    );
  }
}

class BuildCarouselIndicator extends StatelessWidget {
  const BuildCarouselIndicator(
      {Key? key, required this.activeIndex, required this.count})
      : super(key: key);

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedSmoothIndicator(
      activeIndex: activeIndex,
      count: count,
      effect: const JumpingDotEffect(
          dotColor: Colors.white54,
          activeDotColor: Colors.white,
          dotHeight: 10,
          dotWidth: 10),
    );
  }
}
