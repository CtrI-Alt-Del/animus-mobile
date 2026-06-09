enum LegalAreaDto {
  constitucional('CONSTITUCIONAL'),
  administrativo('ADMINISTRATIVO'),
  tributario('TRIBUTÁRIO'),
  previdenciario('PREVIDENCIÁRIO'),
  civil('CIVIL'),
  familiaESucessoes('FAMÍLIA_E_SUCESSÕES'),
  consumidor('CONSUMIDOR'),
  empresarial('EMPRESARIAL'),
  trabalhista('TRABALHISTA'),
  penal('PENAL'),
  ambiental('AMBIENTAL'),
  processual('PROCESSUAL');

  final String value;
  const LegalAreaDto(this.value);
}
