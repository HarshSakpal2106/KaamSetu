enum UserRole { customer, worker }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  final UserRole role;

  // Worker-only fields (null for customers)
  final String? shopAddress;
  final String? workerHours;   // e.g. "Mon–Sat, 9am–7pm"
  final String? description;
  final String? category;      // e.g. "Electrician"
  final String? photoPath;     // asset or remote URL
  final int? visitingCharge;   // in Rupees, e.g. 199 (0 or null = Free/On Call)
  final int? experienceYears;  // in years, e.g. 5 (0 or null = New)

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    this.role = UserRole.customer,
    this.shopAddress,
    this.workerHours,
    this.description,
    this.category,
    this.photoPath,
    this.visitingCharge,
    this.experienceYears,
  });

  bool get isWorker => role == UserRole.worker;

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? email,
    UserRole? role,
    String? shopAddress,
    String? workerHours,
    String? description,
    String? category,
    String? photoPath,
    int? visitingCharge,
    int? experienceYears,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      role: role ?? this.role,
      shopAddress: shopAddress ?? this.shopAddress,
      workerHours: workerHours ?? this.workerHours,
      description: description ?? this.description,
      category: category ?? this.category,
      photoPath: photoPath ?? this.photoPath,
      visitingCharge: visitingCharge ?? this.visitingCharge,
      experienceYears: experienceYears ?? this.experienceYears,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? 'usr_1',
      name: json['name'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: (json['role'] as String?) == 'worker' ? UserRole.worker : UserRole.customer,
      shopAddress: json['shopAddress'] as String?,
      workerHours: json['workerHours'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      photoPath: json['photoPath'] as String?,
      visitingCharge: (json['visitingCharge'] as num?)?.toInt(),
      experienceYears: (json['experienceYears'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'role': role == UserRole.worker ? 'worker' : 'customer',
      'shopAddress': shopAddress,
      'workerHours': workerHours,
      'description': description,
      'category': category,
      'photoPath': photoPath,
      'visitingCharge': visitingCharge,
      'experienceYears': experienceYears,
    };
  }
}
