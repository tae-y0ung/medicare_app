class UserProfile {
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
}