import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/bloc/app_bloc.dart";
import "package:semo/bloc/app_event.dart";
import "package:semo/bloc/app_state.dart";
import "package:semo/components/carousel_slider.dart";
import "package:semo/components/genres_horizontal_list.dart";
import "package:semo/components/horizontal_media_list.dart";
import "package:semo/components/media_card.dart";
import "package:semo/components/media_card_horizontal_list.dart";
import "package:semo/components/snack_bar.dart";
import "package:semo/models/genre.dart";
import "package:semo/models/movie.dart";
import "package:semo/screens/base_screen.dart";
import "package:semo/components/streaming_platform_card_horizontal_list.dart";
import "package:semo/screens/movie_screen.dart";
import "package:semo/enums/media_type.dart";
import "package:semo/utils/urls.dart";

class MoviesScreen extends BaseScreen {
  const MoviesScreen({super.key});

  @override
  BaseScreenState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends BaseScreenState<MoviesScreen> {
  int _currentNowPlayingIndex = 0;

  void _removeFromRecentlyWatched(Movie movie) {
    Timer(const Duration(milliseconds: 500), () {
      context.read<AppBloc>().add(DeleteMovieProgress(movie.id));
    });
  }

  Future<void> _refreshData() async {
    Timer(const Duration(milliseconds: 500), () {
      try {
        context.read<AppBloc>().add(RefreshMovies());
        context.read<AppBloc>().add(const RefreshGenres(MediaType.movies));
      } catch (_) {}
    });
  }

  Widget _buildNowPlaying(List<Movie>? nowPlaying) {
    if (nowPlaying == null || nowPlaying.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider(
      items: nowPlaying,
      currentItemIndex: _currentNowPlayingIndex,
      onItemChanged: (int index) => setState(() => _currentNowPlayingIndex = index),
      onItemTap: (int index) => navigate(MovieScreen(nowPlaying[index])),
      mediaType: MediaType.movies,
    );
  }

  Widget _buildRecentlyWatched(List<Movie>? recentlyWatched) {
    if (recentlyWatched == null || recentlyWatched.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: HorizontalMediaList<Movie>(
        title: "Recently watched",
        items: recentlyWatched,
        itemBuilder: (BuildContext context, Movie movie, int index) => Padding(
          padding: EdgeInsets.only(
            right: index < (recentlyWatched.length) - 1 ? 18 : 0,
          ),
          child: MediaCard(
            media: movie,
            mediaType: MediaType.movies,
            onTap: () => navigate(MovieScreen(movie)),
            showRemoveOption: true,
            onRemove: () => _removeFromRecentlyWatched(movie),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCardHorizontalList({
    required PagingController<int, Movie>? controller,
    required String title,
    required String viewAllSource,
  }) {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: MediaCardHorizontalList(
        title: title,
        pagingController: controller,
        viewAllSource: viewAllSource,
        mediaType: MediaType.movies,
        //ignore: avoid_annotating_with_dynamic
        onTap: (dynamic media) => navigate(MovieScreen(media as Movie)),
      ),
    );
  }

  Widget _buildStreamingPlatforms() => Container(
    margin: const EdgeInsets.only(top: 30),
    child: StreamingPlatformCardHorizontalList(
      mediaType: MediaType.movies,
      viewAllSource: Urls.discoverMovie,
    ),
  );

  Widget _buildGenres(List<Genre>? genres) => Container(
    margin: const EdgeInsets.only(top: 30),
    child: GenresList(
      genres: genres ?? <Genre>[],
      mediaType: MediaType.movies,
      viewAllSource: Urls.discoverMovie,
    ),
  );

  @override
  String get screenName => "Movies";

  @override
  Widget buildContent(BuildContext context) => BlocConsumer<AppBloc, AppState>(
    listener: (BuildContext context, AppState state) {
      if (state.error != null) {
        showSnackBar(context, state.error!);
        context.read<AppBloc>().add(ClearError());
      }
    },
    builder: (BuildContext context, AppState state) => Scaffold(
      body: RefreshIndicator(
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        onRefresh: _refreshData,
        child: !state.isLoadingMovies ? SingleChildScrollView(
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  _buildNowPlaying(state.nowPlayingMovies),
                  _buildRecentlyWatched(state.recentlyWatchedMovies),
                  _buildMediaCardHorizontalList(
                    title: "Trending",
                    controller: state.trendingMoviesPagingController,
                    viewAllSource: Urls.trendingMovies,
                  ),
                  _buildMediaCardHorizontalList(
                    title: "Popular",
                    controller: state.popularMoviesPagingController,
                    viewAllSource: Urls.popularMovies,
                  ),
                  _buildMediaCardHorizontalList(
                    title: "Top rated",
                    controller: state.topRatedMoviesPagingController,
                    viewAllSource: Urls.topRatedMovies,
                  ),
                  _buildStreamingPlatforms(),
                  _buildGenres(state.movieGenres),
                ],
              ),
            ),
          ),
        ) : const Center(child: CircularProgressIndicator()),
      ),
    ),
  );
}