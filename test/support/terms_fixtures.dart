import 'package:muntum/models/terms_model.dart';
import 'package:muntum/services/terms_service.dart';

const testServiceTerms = TermDocument(
  type: 'TERMS_OF_SERVICE',
  version: '1.0.1',
  title: '서비스 이용약관',
  content: '서버에서 받은 서비스 이용약관 본문',
  required: true,
);
const testPrivacyNotice = TermDocument(
  type: 'PRIVACY_POLICY',
  version: '1.0.1',
  title: '개인정보 처리방침',
  content: '서버에서 받은 개인정보 처리방침 본문',
  required: false,
);

SignupConsent testSignupConsent() => SignupConsent([
  const TermAgreement(type: 'TERMS_OF_SERVICE', version: '1.0.1', agreed: true),
]);

class TestTermsService extends TermsService {
  TestTermsService({
    this.documents = const [testServiceTerms, testPrivacyNotice],
  });
  final List<TermDocument> documents;

  @override
  Future<List<TermDocument>> fetchActive() async => documents;
}
