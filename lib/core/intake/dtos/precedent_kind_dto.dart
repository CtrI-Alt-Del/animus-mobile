import 'package:animus/core/intake/dtos/court_dto.dart';

enum PrecedentKindDto {
  sum('SUM'),
  sv('SV'),
  oj('OJ'),
  rg('RG'),
  rr('RR'),
  tr('TR'),
  irdr('IRDR'),
  iac('IAC'),
  puil('PUIL'),
  adi('ADI'),
  adc('ADC'),
  ado('ADO'),
  adpf('ADPF'),
  nt('NT'),
  gr('GR'),
  cont('CONT'),
  sirDr('SIRDR'),
  irr('IRR'),
  ct('CT');

  final String value;
  const PrecedentKindDto(this.value);

  static List<PrecedentKindDto> getValidKindsForCourts(List<CourtDto> courts) {
    if (courts.isEmpty) {
      return PrecedentKindDto.values;
    }

    final Set<PrecedentKindDto> validKinds = <PrecedentKindDto>{};

    for (final CourtDto court in courts) {
      final String name = court.name.toLowerCase();

      if (court == CourtDto.stf) {
        validKinds.addAll(<PrecedentKindDto>[
          PrecedentKindDto.sum,
          PrecedentKindDto.sv,
          PrecedentKindDto.adi,
          PrecedentKindDto.adc,
          PrecedentKindDto.ado,
          PrecedentKindDto.adpf,
        ]);
      } else if (court == CourtDto.stj) {
        validKinds.addAll(<PrecedentKindDto>[
          PrecedentKindDto.sum,
          PrecedentKindDto.irdr,
          PrecedentKindDto.iac,
        ]);
      } else if (court == CourtDto.tst) {
        validKinds.addAll(<PrecedentKindDto>[
          PrecedentKindDto.sum,
          PrecedentKindDto.oj,
          PrecedentKindDto.rr,
          PrecedentKindDto.irr,
          PrecedentKindDto.puil,
        ]);
      } else if (name.startsWith('trt') || court == CourtDto.trts24) {
        validKinds.addAll(<PrecedentKindDto>[
          PrecedentKindDto.rr,
          PrecedentKindDto.oj,
          PrecedentKindDto.tr,
          PrecedentKindDto.irdr,
        ]);
      } else if (name.startsWith('tj') || court == CourtDto.tjs27) {
        validKinds.addAll(<PrecedentKindDto>[
          PrecedentKindDto.sum,
          PrecedentKindDto.irdr,
          PrecedentKindDto.iac,
        ]);
      } else if (name.startsWith('trf') || court == CourtDto.trfs6) {
        validKinds.addAll(<PrecedentKindDto>[
          PrecedentKindDto.sum,
          PrecedentKindDto.irdr,
          PrecedentKindDto.iac,
        ]);
      } else if (court == CourtDto.tse ||
          court == CourtDto.stm ||
          court == CourtDto.tnu) {
        validKinds.addAll(<PrecedentKindDto>[PrecedentKindDto.sum]);
      }
    }

    return validKinds.toList(growable: false);
  }
}
