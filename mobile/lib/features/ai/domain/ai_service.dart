import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';

abstract interface class AiService {
  Future<AiResponse> generate(AiRequest request);
}
