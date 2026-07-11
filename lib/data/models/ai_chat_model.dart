class AIChatMessage {
  final String? id;
  final String role; // "user" | "model"
  final String text;
  final DateTime? createdAt;

  const AIChatMessage({
    this.id,
    required this.role,
    required this.text,
    this.createdAt,
  });

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    // Parse parts: [{ text: "..." }]
    String textVal = '';
    if (json['parts'] is List) {
      final parts = json['parts'] as List;
      if (parts.isNotEmpty && parts[0] is Map) {
        textVal = parts[0]['text']?.toString() ?? '';
      }
    }
    
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString());
    }

    return AIChatMessage(
      id: json['_id']?.toString(),
      role: json['role']?.toString() ?? 'user',
      text: textVal,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'role': role,
      'parts': [
        {'text': text}
      ],
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

class AIChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;
  final List<AIChatMessage> messages;

  const AIChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  factory AIChatSession.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    List<AIChatMessage> parsedMessages = [];
    if (rawMessages is List) {
      parsedMessages = rawMessages
          .map((m) => AIChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return AIChatSession(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Hội thoại mới',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messages: parsedMessages,
    );
  }
}
