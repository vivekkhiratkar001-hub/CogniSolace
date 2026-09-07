/// Model for personal data uploaded or configured by family members / caregivers.
/// Enables deep personalization for elderly dementia patients (e.g. real family photos,
/// familiar voices, real daily routines).
class CaregiverFamilyMember {
  final String id;
  final String name;
  final String relationship; // e.g. "Daughter / Sujata", "Son / Raju", "Grandchild"
  final String? photoPath;    // Local path to family photo
  final String? voiceNotePath; // Recorded greeting audio

  const CaregiverFamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.photoPath,
    this.voiceNotePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'photo_path': photoPath,
    'voice_note_path': voiceNotePath,
  };

  factory CaregiverFamilyMember.fromJson(Map<String, dynamic> json) =>
      CaregiverFamilyMember(
        id: json['id'] as String,
        name: json['name'] as String,
        relationship: json['relationship'] as String,
        photoPath: json['photo_path'] as String?,
        voiceNotePath: json['voice_note_path'] as String?,
      );
}

class CaregiverProfile {
  final String patientId;
  final String preferredRegion; // e.g. 'assam', 'meghalaya', 'generic'
  final String preferredLanguage; // 'en', 'as', 'kha', 'hi'
  final List<CaregiverFamilyMember> familyMembers;
  final List<String> favoriteMarketItems;
  final List<String> personalRoutineSteps;

  const CaregiverProfile({
    required this.patientId,
    this.preferredRegion = 'assam',
    this.preferredLanguage = 'en',
    this.familyMembers = const [],
    this.favoriteMarketItems = const [],
    this.personalRoutineSteps = const [],
  });

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'preferred_region': preferredRegion,
    'preferred_language': preferredLanguage,
    'family_members': familyMembers.map((m) => m.toJson()).toList(),
    'favorite_market_items': favoriteMarketItems,
    'personal_routine_steps': personalRoutineSteps,
  };

  factory CaregiverProfile.fromJson(Map<String, dynamic> json) =>
      CaregiverProfile(
        patientId: json['patient_id'] as String,
        preferredRegion: json['preferred_region'] as String? ?? 'assam',
        preferredLanguage: json['preferred_language'] as String? ?? 'en',
        familyMembers: (json['family_members'] as List<dynamic>?)
                ?.map((m) =>
                    CaregiverFamilyMember.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
        favoriteMarketItems: (json['favorite_market_items'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        personalRoutineSteps: (json['personal_routine_steps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
