import 'package:lifeos/features/ai_companion/friend/domain/ai_friend.dart';

final class FriendSafetyClassifier {
  const FriendSafetyClassifier();

  AiFriendSafetyLevel classify(String message) {
    final normalized = message.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (_crisisSignals.any(normalized.contains)) {
      return AiFriendSafetyLevel.crisis;
    }
    if (_sensitiveSignals.any(normalized.contains)) {
      return AiFriendSafetyLevel.sensitive;
    }
    return AiFriendSafetyLevel.standard;
  }

  static const _crisisSignals = [
    '我想死',
    '我不想活',
    '不想活了',
    '活不下去',
    '结束自己的生命',
    '结束我的生命',
    '杀了自己',
    '伤害自己',
    '我要自杀',
    '想自杀',
    '自残',
    'killmyself',
    'hurtmyself',
    'endmylife',
    'suicide',
  ];

  static const _sensitiveSignals = [
    '抑郁症',
    '焦虑症',
    '恐慌症',
    '停药',
    '吃药',
    '诊断',
    '医生',
    '心理咨询',
    '欠债',
    '借贷',
    '投资',
    '股票',
    '法律',
    '律师',
  ];
}
