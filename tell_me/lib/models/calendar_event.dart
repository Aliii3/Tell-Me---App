import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String dateKey; // "yyyy-MM-dd"
  final String title;
  final String time;
  final String duration;
  final String category;
  final Color backgroundColor;
  final Color? textColor;
  final List<String> avatars;
  final bool hasVideo;

  CalendarEvent({
    required this.id,
    required this.dateKey,
    required this.title,
    required this.time,
    required this.duration,
    required this.category,
    required this.backgroundColor,
    this.textColor,
    this.avatars = const [],
    this.hasVideo = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'title': title,
        'time': time,
        'duration': duration,
        'category': category,
        'backgroundColorValue': backgroundColor.toARGB32(),
        'textColorValue': textColor?.toARGB32(),
        'avatars': avatars,
        'hasVideo': hasVideo,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        dateKey: json['dateKey'] as String,
        title: json['title'] as String,
        time: json['time'] as String,
        duration: json['duration'] as String,
        category: json['category'] as String,
        backgroundColor: Color(json['backgroundColorValue'] as int),
        textColor: json['textColorValue'] != null
            ? Color(json['textColorValue'] as int)
            : null,
        avatars: (json['avatars'] as List<dynamic>?)?.cast<String>() ?? [],
        hasVideo: json['hasVideo'] as bool? ?? false,
      );
}
