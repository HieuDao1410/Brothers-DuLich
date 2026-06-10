class ScheduleModel {
  final int id;
  final String title; 
  final String startDate;
  final String endDate;
  final String status; 

  ScheduleModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? 'Sắp tới',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
    };
  }
}