const movies = "https://www.goojara.to/watch-movies-popular";
const tvs = "https://www.goojara.to/watch-series-popular";

const String kfAppName = "Rock Flix";

const kfAppParentDir = "$kfAppName/data";

const backDropImagesDir = "popular/backdrop-images";

const kfOriginalTMDBImageUrl = "https://image.tmdb.org/t/p/original";
const kfTMDBaseUrl = "https://api.themoviedb.org";
const kfTMDBAPIKEY = "727c59ab265fc8dfe32a7786b0cb2a96";

String kfTMDBSearchImagesUrl({required String type, required String id}) =>
    "https://api.themoviedb.org/3/$type/$id/images?api_key=$kfTMDBAPIKEY";

const String backdropPath = "images/backdrops";
const String logoPath = "images/logos";
const String infoPath = "info";

String kfTMDBSearchMoviesORSeriesUrl(
        {required String type,
        required String? year,
        required String query,
        bool includeAdult = true}) =>
    "$kfTMDBaseUrl/3/search/$type?api_key=$kfTMDBAPIKEY&query=$query&include_adult=$includeAdult&year=$year";
