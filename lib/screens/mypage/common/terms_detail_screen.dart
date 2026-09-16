import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class TermsDetailScreen extends StatelessWidget {
  final String title;

  const TermsDetailScreen({super.key, required this.title});

  bool get _isServiceTerms => title.contains('서비스');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: title,
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 48.h),
              child: _isServiceTerms
                  ? const _ServiceTermsContent()
                  : const _PrivacyPolicyContent(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTermsContent extends StatelessWidget {
  const _ServiceTermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _TermsSection(
          title: '제 1 조 (목적)',
          paragraphs: [
            "본 약관은 ‘문틈 앱’이 제공하는 어플리케이션(이하 '서비스')을 이용함에 있어, ‘문틈 앱’과 이용자의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.",
            '이용자는 서비스에 접속하거나 서비스를 이용함으로써 본 약관에 동의한 것으로 간주됩니다. 약관에 동의하지 않을 경우 서비스 이용이 제한될 수 있습니다.',
          ],
        ),
        _TermsSection(
          title: '제 2 조 (용어의 정의)',
          paragraphs: [
            "'서비스'란 ‘문틈 앱’이 단말기(PC, 모바일, 태블릿 등)와 상관없이 제공하는 모든 어플리케이션 및 관련 제반 서비스를 의미합니다.",
            "'이용자'란 어플리케이션에 접속하여 본 약관에 따라 ‘문틈 앱’이 제공하는 서비스를 이용하는 회원 및 비회원을 말합니다.",
            '‘회원’이란 서비스 이용 계약을 체결하고, 회원 아이디(ID)를 부여받은 이용자를 말합니다.',
            '‘비회원’이란 ‘회원’이 아닌 이용자를 말합니다.',
          ],
          numbered: true,
        ),
        _TermsSection(
          title: '제 3 조 (약관의 효력 및 개정)',
          paragraphs: [
            '본 약관은 어플리케이션 초기 회원가입 화면 및 이미 가입한 회원의 경우 마이페이지를 통해 이용자에게 공지함으로써 효력이 발생합니다.',
            '‘문틈 앱’은 법령 변경, 서비스 내용 변경 등 합리적인 사유가 있는 경우 관련 법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있으며, 개정된 약관은 적용 일자 7일 전부터 공지합니다.',
            '이용자가 변경된 약관의 효력 발생일 이후에도 서비스를 계속 이용하는 경우, 변경된 약관에 동의한 것으로 간주됩니다.',
          ],
          numbered: true,
        ),
        _TermsSection(
          title: '제 4 조 (서비스의 변경 및 중단)',
          paragraphs: [
            '‘문틈 앱’은 다음과 같은 경우 사전 공지 없이 서비스의 전부 또는 일부를 변경하거나 중단할 수 있습니다.',
          ],
          bullets: [
            '서비스 개선, 기능 추가/변경 및 유지 보수 필요 시',
            '기술적, 운영상 불가피한 사유가 발생한 경우',
            '관련 법령 또는 정책 변경으로 인한 조정이 필요한 경우',
          ],
        ),
        _TermsSection(
          title: '제 5 조 (회원 아이디 및 비밀번호 관리 의무 등)',
          paragraphs: [
            '회원은 계정 및 비밀번호 등 로그인 정보의 기밀을 유지할 책임이 있으며, 제 3자에게 이용 허락할 수 없습니다. 다만, ‘문틈 앱’이 동의한 경우에는 그러하지 않습니다.',
            '계정의 무단 사용이 발생한 경우 즉시 ‘문틈 앱’에 알려야 합니다.',
            '제1항 본문 위반 및 이용자의 관리 소홀로 인해 발생한 손해에 대해서는 ‘문틈 앱’이 책임을 지지 않습니다.',
            '제2항의 경우, 회원이 ‘문틈 앱’에게 그 사실을 통지하지 않거나 통지한 경우에도 ‘문틈 앱’의 안내에 따르지 않아 발생한 회원의 피해에 대해 회사는 책임을 지지 않습니다. 다만, ‘문틈 앱’에게 책임있는 경우에는 그 범위 내에서 책임을 부담합니다.',
            '회원은 도용 등을 방지하기 위해 주기적으로 비밀번호를 변경하며, ‘문틈 앱’은 회원에게 비밀번호의 변경을 권고할 수 있습니다.',
          ],
          numbered: true,
        ),
        _TermsSection(
          title: '제 6 조 (이용자의 의무)',
          paragraphs: ['이용자는 서비스를 이용할 때 아래의 행위를 하여서는 안 됩니다.'],
          bullets: [
            '관련 법령 또는 본 약관을 위반하는 행위',
            '타인의 개인정보 또는 계정을 도용하는 행위',
            '서비스의 정상적인 운영을 방해하거나 장애를 유발하는 행위',
            '허가되지 않은 자동화 프로그램, 스크립트, 크롤러 등을 사용하는 행위',
            '타인에게 불쾌감, 피해를 주거나 괴롭히는 행위',
            '‘문틈 앱’ 및 제 3자의 지적재산권 침해 또는 명예 훼손 행위',
            '기타 공공질서 및 선량한 풍속에 반하는 행위',
          ],
        ),
        _TermsSection(
          title: '제 7 조 (회원 탈퇴 및 이용 제한)',
          paragraphs: [
            '이용자는 언제든지 서비스 탈퇴를 요청할 수 있으며, ‘문틈 앱’은 즉시 회원 탈퇴를 처리합니다.',
            '이용자가 본 약관의 의무를 위반한 경우, ‘문틈 앱’은 사전 통지 없이 서비스 이용을 제한하거나 이용계약을 해지할 수 있습니다.',
          ],
          numbered: true,
        ),
        _TermsSection(
          title: '제 8 조 (저작권 등의 귀속)',
          paragraphs: [
            '서비스가 창작한 저작물(콘텐츠, 디자인, 소프트웨어, 로고 등)에 대한 저작권 기타 지식재산권은 ‘문틈 앱’ 또는 해당 권리자에 귀속되며, 국내외 저작권법 및 관련 법령에 의해 보호됩니다.',
            '이용자는 ‘문틈 앱’의 사전 서면 동의 없이 서비스 내 콘텐츠를 복제, 배포, 수정, 출판, 2차적 저작물 작성 등 영리 목적으로 이용할 수 없습니다.',
          ],
          numbered: true,
        ),
        _TermsSection(
          title: '제 9 조 (면책 조항)',
          paragraphs: [
            '‘문틈 앱’은 천재지변, 불가항력, 통신망 장애, 기간통신사업자의 서비스 중단 등으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 대한 책임이 면제됩니다.',
            '이용자의 귀책사유로 인한 서비스 이용 장애나 손해에 대하여 ‘문틈 앱’은 책임을 지지 않습니다.',
          ],
          numbered: true,
        ),
        _TermsSection(
          title: '제 10 조 (준거법 및 관할)',
          paragraphs: [
            '본 약관은 ‘문틈 앱’이 서비스를 제공하는 지역의 법률을 준거법으로 하며, 서비스 이용과 관련하여 ‘문틈 앱’과 이용자 간에 분쟁이 발생한 경우 관련 법령이 정하는 관할 법원을 전속 관할로 합니다.',
          ],
        ),
        _TermsSection(
          title: '제 11 조 (이용약관 관련 문의처)',
          paragraphs: ['이용약관과 관련된 문의는 아래로 연락해 주세요.'],
          bullets: ['이메일: muntum510@gmail.com'],
          isLast: true,
        ),
      ],
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final bool numbered;
  final bool isLast;

  const _TermsSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.numbered = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 48.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.title2),
          SizedBox(height: 13.h),
          ...paragraphs.asMap().entries.map((entry) {
            final index = entry.key;
            final text = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == paragraphs.length - 1 && bullets.isEmpty
                    ? 0
                    : 13.h,
              ),
              child: _TermsParagraph(
                text: numbered ? '${index + 1}. $text' : text,
              ),
            );
          }),
          ...bullets.asMap().entries.map((entry) {
            final index = entry.key;
            final text = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == bullets.length - 1 ? 0 : 8.h,
              ),
              child: _TermsBullet(text: text),
            );
          }),
        ],
      ),
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _TermsSection(
          title: '개인정보 처리방침',
          paragraphs: [
            '‘문틈 앱’은 개인정보 보호법 등 국내 개인정보 보호 및 관련 법령을 준수합니다. 본 개인정보 처리방침은 ‘문틈 앱’이 운영하는 어플리케이션(이하 ‘앱’ 또는 ‘서비스’)에 적용됩니다.',
            '본 방침은 ‘문틈 앱’이 수집하는 개인정보의 항목, 이용 목적, 보관 및 파기, 이용자의 권리 등에 관한 내용을 안내합니다.',
          ],
        ),
        _TermsSection(
          title: '제 1 조 (수집하는 개인정보 항목)',
          paragraphs: [
            '회원가입 시: 이메일 주소, 비밀번호, 이름 또는 닉네임',
            '지도 서비스 이용 시: 이용자가 위치 권한을 허용한 경우 현재 위치',
            '문의 또는 제보 시: 이메일 주소, 이름 또는 닉네임, 이용자가 자발적으로 입력한 내용',
            '서비스 이용 과정에서 생성되는 정보: 인증 토큰, 접속 일시, 앱 버전, 오류 로그 등 서비스 운영에 필요한 기술적 정보',
            '서비스 이용 분석 시: 앱 사용 기록, 화면 조회 기록, 기능 클릭 기록, 세션 정보, 앱 이용 및 체류시간, 앱 인스턴스 식별자, 기기 유형, 운영체제 정보, 앱 버전. 로그인한 경우 이메일이나 닉네임이 아닌 서비스 내부 회원 식별자가 함께 처리될 수 있습니다.',
          ],
          numbered: true,
        ),
        _TermsSection(
          title: '제 2 조 (개인정보의 수집 및 이용 목적)',
          bullets: [
            '회원가입, 로그인, 회원 식별 및 회원 관리',
            '현재 위치 기반 주변 프로그램 목록 및 검색 서비스 제공',
            '이용자 문의 응대 및 고객 지원',
            '공지사항 전달 및 서비스 관련 안내',
            '서비스 안정성 확보, 오류 확인 및 부정 이용 방지',
            '서비스 이용 현황 분석, 사용자 경험 파악, 기능 및 서비스 개선',
            '법령상 의무 이행 및 분쟁 대응',
          ],
        ),
        _TermsSection(
          title: '제 3 조 (개인정보의 보유 및 파기)',
          paragraphs: [
            '회원의 개인정보는 원칙적으로 회원 탈퇴 시 지체 없이 파기됩니다.',
            '다만, 관련 법령에 따라 보관이 필요한 정보는 해당 법령에서 정한 기간 동안 보관될 수 있습니다.',
            'Google Analytics for Firebase를 통해 수집되는 사용자 단위 및 이벤트 단위 데이터는 수집일로부터 최대 14개월 동안 보관한 후 삭제합니다. 개인을 직접 식별할 수 없도록 집계된 통계 및 보고서는 서비스 개선을 위해 더 오래 보관될 수 있습니다.',
            '보유 기간이 지나거나 처리 목적이 달성된 개인정보는 복구가 불가능한 방법으로 안전하게 파기합니다.',
          ],
        ),
        _TermsSection(
          title: '제 4 조 (개인정보의 제 3자 제공)',
          paragraphs: [
            '‘문틈 앱’은 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 다만, 이용자가 사전에 동의한 경우 또는 법령에 따라 요구되는 경우에는 예외적으로 제공될 수 있습니다.',
          ],
        ),
        _TermsSection(
          title: '제 5 조 (개인정보 처리 위탁)',
          paragraphs: [
            '‘문틈 앱’은 서비스 제공과 안정적인 운영을 위해 개인정보 처리를 외부 업체에 위탁할 수 있으며, 이 경우 관련 법령에 따라 필요한 보호조치를 이행합니다.',
          ],
          bullets: [
            'Amazon Web Services (AWS): 서비스 서버 및 데이터 보관',
            'CloudFront (AWS): 콘텐츠 전송 네트워크(CDN) 제공',
            'Google LLC: Google Analytics for Firebase를 통한 앱 이용 현황 분석 및 통계 제공',
          ],
        ),
        _TermsSection(
          title: '제 6 조 (이용자의 권리와 행사 방법)',
          bullets: [
            '개인정보 열람, 정정, 삭제, 처리정지를 요청할 수 있습니다.',
            '회원 탈퇴를 통해 개인정보 수집 및 이용 동의를 철회할 수 있습니다.',
            '위치정보 등 선택 동의 항목은 앱 또는 기기 설정에서 변경할 수 있습니다.',
            '권리 행사는 muntum510@gmail.com 으로 요청할 수 있습니다.',
          ],
        ),
        _TermsSection(
          title: '제 7 조 (쿠키 및 유사 기술)',
          paragraphs: [
            '‘문틈 앱’은 모바일 앱으로 제공되며, 로그인 상태 유지와 서비스 이용 편의를 위해 인증 토큰 및 앱 내 로컬 저장 기술을 사용할 수 있습니다.',
            '로그인 시 발급된 액세스 토큰과 리프레시 토큰은 API 요청 시 인증 목적으로 사용됩니다. 로그아웃 또는 회원 탈퇴 시 관련 인증 정보는 삭제되거나 무효화됩니다.',
          ],
        ),
        _TermsSection(
          title: '제 8 조 (Google Analytics for Firebase의 사용)',
          paragraphs: [
            '‘문틈 앱’은 서비스 이용 현황을 분석하고 사용자 경험과 기능을 개선하기 위해 Google LLC가 제공하는 Google Analytics for Firebase를 사용합니다.',
            '이 과정에서 앱 사용 기록, 화면 조회 기록, 기능 클릭 기록, 세션 정보, 앱 이용 및 체류시간, 앱 인스턴스 식별자, 기기 유형, 운영체제 정보, 앱 버전 등이 자동으로 수집될 수 있습니다. 로그인한 이용자의 경우 이메일이나 닉네임이 아닌 서비스 내부 회원 식별자가 분석 정보와 연결될 수 있습니다.',
            'Google은 ‘문틈 앱’을 대신하여 분석 서비스를 제공하는 처리 수탁자로서 해당 데이터를 처리합니다. Google의 데이터 처리에 관한 자세한 내용은 Google 개인정보처리방침(https://policies.google.com/privacy) 및 Firebase 개인정보 보호 및 보안 안내(https://firebase.google.com/support/privacy)에서 확인할 수 있습니다.',
            '분석 데이터는 수집일로부터 최대 14개월 동안 보관한 후 삭제합니다. 다만 개인을 직접 식별할 수 없도록 집계된 통계 및 보고서는 서비스 개선을 위해 더 오래 보관될 수 있습니다.',
            '이용자는 앱 사용을 중단하고 앱을 삭제하여 이후의 분석 정보 수집을 중단할 수 있습니다. 이미 수집된 분석 정보의 삭제 또는 처리 정지를 원하는 경우 개인정보 관련 문의처로 요청할 수 있으며, 요청자 확인 후 관련 법령과 Google의 데이터 삭제 절차에 따라 처리합니다.',
          ],
        ),
        _TermsSection(
          title: '제 9 조 (개인정보 보호를 위한 조치)',
          bullets: [
            '이용자의 비밀번호는 복호화가 어려운 방식으로 암호화하여 저장합니다.',
            '앱과 서버 간 통신에는 HTTPS를 적용하여 전송 구간을 보호합니다.',
            '회원 식별 정보에 접근하는 요청은 인증 토큰 검증을 거칩니다.',
            '서비스 운영에 필요한 권한을 최소한으로 관리합니다.',
            '서비스 오류와 보안 이슈를 확인하기 위한 점검을 수행합니다.',
          ],
        ),
        _TermsSection(
          title: '제 10 조 (개인정보 처리방침 변경)',
          paragraphs: [
            '본 개인정보 처리방침은 관련 법령 또는 서비스 내용 변경에 따라 수정될 수 있습니다. 중요한 변경 사항이 있는 경우 서비스 내 공지 등을 통해 안내합니다.',
          ],
        ),
        _TermsSection(
          title: '제 11 조 (개인정보 관련 문의처)',
          paragraphs: ['개인정보와 관련된 문의는 아래로 연락해 주세요.'],
          bullets: ['이메일: muntum510@gmail.com'],
          isLast: true,
        ),
      ],
    );
  }
}

class _TermsParagraph extends StatelessWidget {
  final String text;

  const _TermsParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body1.copyWith(color: AppColors.gray800),
    );
  }
}

class _TermsBullet extends StatelessWidget {
  final String text;

  const _TermsBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '- ',
          style: AppTypography.body1.copyWith(color: AppColors.gray800),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body1.copyWith(color: AppColors.gray800),
          ),
        ),
      ],
    );
  }
}
