import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../data/repositories/post_repository.dart';

class HomeProvider extends ChangeNotifier {
  final IPostRepository _postRepository;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  HomeProvider(this._postRepository);

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _postRepository.getFeed();
    } catch (e) {
      _errorMessage = 'Không thể tải bảng tin. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logic pull to refresh
  Future<void> refreshFeed() async {
    await fetchFeed();
  }
}
