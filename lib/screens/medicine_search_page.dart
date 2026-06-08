import 'package:flutter/material.dart';

class MedicineSearchPage extends StatelessWidget {
  const MedicineSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약 검색'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('약 검색 페이지 준비 중'),
      ),
    );
  }
}