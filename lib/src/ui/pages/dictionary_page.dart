import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/data/models/word_model.dart';
import 'package:super_teclas/src/data/words/word_bank.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final _searchController = TextEditingController();
  String _selectedDifficulty = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final allWords = WordBank.getWords(
      Localizations.localeOf(context).languageCode,
    );

    final filteredWords = allWords.where((word) {
      final matchesSearch = _searchQuery.isEmpty ||
          word.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          word.definition.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDifficulty = _selectedDifficulty == 'all' ||
          word.difficulty == _selectedDifficulty;
      return matchesSearch && matchesDifficulty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(strings.dictionary),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 48 : 16,
          vertical: 16,
        ),
        child: Column(
          children: [
            _buildSearchField(strings),
            const SizedBox(height: 12),
            _buildFilterChips(strings),
            const SizedBox(height: 16),
            Expanded(
              child: filteredWords.isEmpty
                  ? _buildEmptyState(strings)
                  : _buildWordList(filteredWords, isWide),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(AppStrings strings) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
      decoration: InputDecoration(
        hintText: strings.searchHint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppStrings strings) {
    return Row(
      children: [
        _buildChip(strings.allWords, 'all'),
        const SizedBox(width: 8),
        _buildChip(strings.easy, 'easy'),
        const SizedBox(width: 8),
        _buildChip(strings.medium, 'medium'),
        const SizedBox(width: 8),
        _buildChip(strings.hard, 'hard'),
      ],
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _selectedDifficulty == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedDifficulty = value);
      },
      selectedColor: Colors.blue[700],
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[400],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings strings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            strings.noResults,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(List<WordModel> words, bool isWide) {
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        word.text,
                        style: TextStyle(
                          fontSize: isWide ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDifficultyBadge(word.difficulty),
                  ],
                ),
                if (word.definition.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    word.definition,
                    style: TextStyle(
                      fontSize: isWide ? 14 : 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    final color = switch (difficulty) {
      'easy' => Colors.green,
      'medium' => Colors.orange,
      'hard' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
