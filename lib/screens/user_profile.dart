class UserProfile {
  final String userId;

  final String name;
  final String email;
  final String phone;
  final String gender;
  final String pregnancy;
  final String birthYear;
  final String birthMonth;
  final String birthDay;
  final String guardianPhone;

  const UserProfile({
    this.userId = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.pregnancy,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
    this.guardianPhone = '',
  });

  factory UserProfile.empty() {
    return const UserProfile(
      userId: '',
      name: '',
      email: '',
      phone: '',
      gender: '',
      pregnancy: '',
      birthYear: '',
      birthMonth: '',
      birthDay: '',
      guardianPhone: '',
    );
  }

  factory UserProfile.fromJson(
  Map<String, dynamic> json,
) {
  return UserProfile(
    userId:
        json['userId']
            ?.toString() ??
        '',

    name:
        json['name']
            ?.toString() ??
        '',

    email:
        json['email']
            ?.toString() ??
        '',

    phone:
        json['phone']
            ?.toString() ??
        '',

    gender:
        json['gender']
            ?.toString() ??
        '',

    pregnancy:
        json['pregnancy']
            ?.toString() ??
        '',

    birthYear:
        json['birthYear']
            ?.toString() ??
        '',

    birthMonth:
        json['birthMonth']
            ?.toString() ??
        '',

    birthDay:
        json['birthDay']
            ?.toString() ??
        '',

    guardianPhone:
        json['guardianPhone']
            ?.toString() ??
        '',
  );
}

}