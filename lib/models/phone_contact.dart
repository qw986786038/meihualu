class PhoneContact {
  const PhoneContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.section,
  });

  final String id;
  final String name;
  final String phone;
  final String section;
}

const kMockPhoneContacts = [
  PhoneContact(id: 'c1', name: '阿姨', phone: '18545562055', section: 'A'),
  PhoneContact(id: 'c2', name: '宝宝', phone: '18104550367', section: 'A'),
  PhoneContact(id: 'c3', name: '车3', phone: '15504898103', section: 'B'),
  PhoneContact(id: 'c4', name: '车险1', phone: '18246168191', section: 'B'),
  PhoneContact(
    id: 'c5',
    name: '车险太平洋1',
    phone: '15846609165',
    section: 'B',
  ),
  PhoneContact(
    id: 'c6',
    name: '车险人保2',
    phone: '18846468436',
    section: 'B',
  ),
  PhoneContact(
    id: 'c7',
    name: '车险续费',
    phone: '15846609165',
    section: 'B',
  ),
  PhoneContact(
    id: 'c8',
    name: '车险续费15546062878',
    phone: '15546062878',
    section: 'C',
  ),
  PhoneContact(
    id: 'c9',
    name: '车险张续费15114650128',
    phone: '15114650128',
    section: 'C',
  ),
  PhoneContact(
    id: 'c10',
    name: '大安农机器4',
    phone: '18845816678',
    section: 'D',
  ),
  PhoneContact(
    id: 'c11',
    name: '房屋中介',
    phone: '13796662055',
    section: 'F',
  ),
];

const kPhoneContactIndexLetters = [
  'A',
  'B',
  'C',
  'D',
  'F',
  'G',
  'H',
  'J',
  'K',
  'L',
  'M',
  'P',
  'S',
  'W',
  'X',
  'Y',
  'Z',
  '#',
];
