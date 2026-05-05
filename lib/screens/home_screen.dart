import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../data/repositories/post_repository.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // View -> Provider: Bọc Provider riêng cho màn hình Home
    return ChangeNotifierProvider(
      create: (context) => HomeProvider(
        context.read<IPostRepository>(),
      )..fetchFeed(), // Kích hoạt fetch data ngay khi khởi tạo
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(child: Text(provider.errorMessage!));
        }

        return RefreshIndicator(
          onRefresh: provider.refreshFeed,
          child: ListView.builder(
            itemCount: provider.posts.length,
            itemBuilder: (context, index) {
              final post = provider.posts[index];
              return PostCard(post: post);
            },
          ),
        );
      },
    );
  }
}