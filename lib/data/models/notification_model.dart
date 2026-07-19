class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? link;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.link,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt']?.toString();
    return NotificationModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      link: json['link']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: rawDate != null ? DateTime.tryParse(rawDate) : null,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      description: description,
      type: type,
      link: link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// One page of the inbox plus the unread badge count.
class NotificationInbox {
  final List<NotificationModel> items;
  final int unreadCount;

  const NotificationInbox({required this.items, required this.unreadCount});
}
