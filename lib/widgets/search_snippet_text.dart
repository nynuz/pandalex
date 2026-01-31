import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';

class SearchSnippetText extends StatelessWidget {
  final String snippet;
  final List<int>? highlightPositions;
  
  const SearchSnippetText({
    Key? key,
    required this.snippet,
    this.highlightPositions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (highlightPositions == null || highlightPositions!.isEmpty) {
      return Text(
        snippet,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    final start = highlightPositions![0];
    final end = highlightPositions![1];
    
    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: GoogleFonts.lato(textStyle: AppConstants.textSnippet),
        children: [
          TextSpan(text: snippet.substring(0, start)),
          TextSpan(
            text: snippet.substring(start, end),
            style: const TextStyle(
              backgroundColor: Color(0xFF0bf34f), // Verde P.An.D.A
            ),
          ),
          TextSpan(text: snippet.substring(end)),
        ],
      ),
    );
  }
}