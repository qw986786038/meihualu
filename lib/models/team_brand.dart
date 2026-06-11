enum TeamBrandSource {
  preset,
  album,
  textGenerated,
}

class TeamBrandSelection {
  const TeamBrandSelection({
    required this.displayName,
    required this.source,
    this.imagePath,
    this.presetId,
  });

  final String displayName;
  final TeamBrandSource source;
  final String? imagePath;
  final String? presetId;
}

class TeamBrandPreset {
  const TeamBrandPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.shortLabel,
    required this.backgroundColor,
    this.textColor = 0xFF333333,
  });

  final String id;
  final String name;
  final String category;
  final String shortLabel;
  final int backgroundColor;
  final int textColor;
}

const List<String> kTeamBrandCategories = [
  '使用热门',
  '建筑工程',
  '物业管理',
  '快消销售',
];

const List<TeamBrandPreset> kTeamBrandPresets = [
  TeamBrandPreset(
    id: 'cscec',
    name: '中国建筑',
    category: '使用热门',
    shortLabel: 'CSCEC',
    backgroundColor: 0xFF005BAC,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'powerchina',
    name: '中国电建',
    category: '使用热门',
    shortLabel: 'POWERCHINA',
    backgroundColor: 0xFFE8F1FF,
    textColor: 0xFF005BAC,
  ),
  TeamBrandPreset(
    id: 'muyuan',
    name: '牧原',
    category: '使用热门',
    shortLabel: 'MUYUAN',
    backgroundColor: 0xFFF5F5F5,
  ),
  TeamBrandPreset(
    id: 'chint',
    name: '正泰',
    category: '使用热门',
    shortLabel: 'CHINT',
    backgroundColor: 0xFFF5F5F5,
  ),
  TeamBrandPreset(
    id: 'mixue',
    name: '蜜雪冰城',
    category: '使用热门',
    shortLabel: 'MXBC',
    backgroundColor: 0xFFFFF3E8,
    textColor: 0xFFE60012,
  ),
  TeamBrandPreset(
    id: 'picc',
    name: '中国人保',
    category: '使用热门',
    shortLabel: 'PICC',
    backgroundColor: 0xFFE60012,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'lianjia',
    name: '链家',
    category: '使用热门',
    shortLabel: 'LJ',
    backgroundColor: 0xFF00AE66,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'telecom',
    name: '中国电信',
    category: '使用热门',
    shortLabel: '5G',
    backgroundColor: 0xFF005BAC,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'unicom',
    name: '中国联通',
    category: '使用热门',
    shortLabel: 'UNICOM',
    backgroundColor: 0xFFE60012,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'mobile',
    name: '中国移动',
    category: '使用热门',
    shortLabel: 'CMCC',
    backgroundColor: 0xFF0085D0,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'construction_1',
    name: '中建八局',
    category: '建筑工程',
    shortLabel: 'CSCEC8',
    backgroundColor: 0xFF005BAC,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'construction_2',
    name: '中铁建',
    category: '建筑工程',
    shortLabel: 'CRCC',
    backgroundColor: 0xFFE8F1FF,
    textColor: 0xFF005BAC,
  ),
  TeamBrandPreset(
    id: 'property_1',
    name: '万科物业',
    category: '物业管理',
    shortLabel: 'VANKE',
    backgroundColor: 0xFFF5F5F5,
  ),
  TeamBrandPreset(
    id: 'property_2',
    name: '碧桂园服务',
    category: '物业管理',
    shortLabel: 'BGY',
    backgroundColor: 0xFF00AE66,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'sales_1',
    name: '可口可乐',
    category: '快消销售',
    shortLabel: 'COKE',
    backgroundColor: 0xFFE60012,
    textColor: 0xFFFFFFFF,
  ),
  TeamBrandPreset(
    id: 'sales_2',
    name: '农夫山泉',
    category: '快消销售',
    shortLabel: 'NFSQ',
    backgroundColor: 0xFFE8F8FF,
    textColor: 0xFF0085D0,
  ),
];
