import 'package:flutter/material.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/space_manager/data/space_repository_interface.dart';
import 'package:unburden_app/features/space_manager/domain/space_parser.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

class SpaceInputScreen extends StatefulWidget {
  final LlmClient llm;
  final SpaceRepositoryInterface repository;

  const SpaceInputScreen({
    super.key,
    required this.llm,
    required this.repository,
  });

  @override
  State<SpaceInputScreen> createState() => _SpaceInputScreenState();
}

class _SpaceInputScreenState extends State<SpaceInputScreen> {
  final _controller = TextEditingController();
  List<StorageLocation> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    await widget.repository.init();
    final locations = await widget.repository.getAll();

    if (!mounted) return;

    setState(() => _locations = locations);
  }

  Future<void> _onSubmit() async {
    final parser = SpaceParser(llm: widget.llm);
    final location = await parser.parse(_controller.text);
    await widget.repository.add(location);
    await _loadLocations();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _controller),
            ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('Add location'),
            ),
            ..._locations.expand((loc) => [
              Text(loc.name),
              ...loc.contents.map((c) => Text(c)),
            ]),
          ],
        ),
      ),
    );
  }
}