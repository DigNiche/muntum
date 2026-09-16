enum CuratorApplicationStatus { notApplied, pending, rejected }

extension CuratorApplicationStatusLabel on CuratorApplicationStatus {
  String get label {
    switch (this) {
      case CuratorApplicationStatus.notApplied:
        return '';
      case CuratorApplicationStatus.pending:
        return '심사중';
      case CuratorApplicationStatus.rejected:
        return '미승인';
    }
  }
}

class CuratorApplicationViewData {
  const CuratorApplicationViewData({
    required this.status,
    required this.programName,
    required this.appliedAt,
    required this.summary,
    required this.introduction,
    this.rejectionReason,
  });

  final CuratorApplicationStatus status;
  final String programName;
  final String appliedAt;
  final String summary;
  final String introduction;
  final String? rejectionReason;

  static const pendingSample = CuratorApplicationViewData(
    status: CuratorApplicationStatus.pending,
    programName: '2026년 한국 근대 거장전',
    appliedAt: '2026.12.12',
    summary: '산을 품은 화가, 유영국의 가장 큰 회고전',
    introduction:
        '변하지 않는 자신만의 기준을 지킨다는 것. 그것이 얼마나 단단하고도 고독한 일인지, 이번 전시는 색과 선을 통해 조용히 보여준다. 잠시 걸음을 멈추고 한 화가가 평생 품어온 산을 들여다보는 시간, 한 번쯤 가져볼 만하다. 변하지 않는 자신만의 기준을 지킨다는 것. 그것이 얼마나 단단하고도 고독한 일인지, 이번 전시는 색과 선을 통해 조용히 보여준다. 잠시 걸음을 멈추고 한 화가가 평생 품어온 산을 들여다보는 시간, 한 번쯤 가져볼 만하다.',
  );

  static const rejectedSample = CuratorApplicationViewData(
    status: CuratorApplicationStatus.rejected,
    programName: '2026년 한국 근대 거장전',
    appliedAt: '2026.12.12',
    summary: '산을 품은 화가, 유영국의 가장 큰 회고전',
    introduction:
        '변하지 않는 자신만의 기준을 지킨다는 것. 그것이 얼마나 단단하고도 고독한 일인지, 이번 전시는 색과 선을 통해 조용히 보여준다.',
    rejectionReason: '작성 가이드라인과 맞지 않아 승인되지 않았습니다. 확인 후 재신청해 주세요.',
  );
}
