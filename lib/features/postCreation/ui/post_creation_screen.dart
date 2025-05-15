import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:state/core/constants/regions.dart';
import 'package:state/features/postCreation/bloc/post_creation_cubit.dart';
import 'package:state/features/postCreation/bloc/post_creation_state.dart';
import 'package:state/features/home/ui/filters_row.dart';

class PostCreationScreen extends StatefulWidget {
  const PostCreationScreen({super.key});

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  String selectedRegion = kRegions.first;
  final TextEditingController contentController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    PermissionStatus status;
    if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      // Android 13+ uses READ_MEDIA_IMAGES, older uses storage
      status = await Permission.storage.request();
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
    }
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied to access photos.')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoColor = const Color(0xFF800020);

    return BlocConsumer<PostCreationCubit, PostCreationState>(
      listener: (context, state) {
        if (state is PostCreationSuccess) {
          Navigator.of(context).pop(true);
        } else if (state is PostCreationError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Create Post'),
            backgroundColor: logoColor,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  FancyDropdown(
                    value: selectedRegion,
                    items: kRegions,
                    icon: Icons.public,
                    onChanged:
                        (region) => setState(() => selectedRegion = region),
                    color: logoColor,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, height: 180),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logoColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.image),
                        label: const Text('Add Image'),
                        onPressed: _pickImage,
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: logoColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          state is PostCreationLoading
                              ? null
                              : () {
                                final content = contentController.text.trim();
                                if (content.isNotEmpty) {
                                  context.read<PostCreationCubit>().createPost(
                                    region: selectedRegion,
                                    content: content,
                                    imageFile: _selectedImage,
                                  );
                                }
                              },
                      child:
                          state is PostCreationLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('Post'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
