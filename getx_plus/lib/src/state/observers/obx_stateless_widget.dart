import 'package:flutter/widgets.dart';

import 'obx_element.dart';

abstract class ObxStatelessWidget extends StatelessWidget {
  const ObxStatelessWidget({super.key});

  @override
  StatelessElement createElement() => ObxElement(this);
}
