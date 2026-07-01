import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/watermark_style_option.dart';

class TeamWatermarkStylePickerPage extends StatelessWidget {
  const TeamWatermarkStylePickerPage({super.key});

  void _onStyleTap(BuildContext context, WatermarkStyleOption option) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已选择「${option.title}」样式，编辑功能开发中')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: const Color(0xFF333333),
                  ),
                  const Expanded(
                    child: Text(
                      '选择水印样式',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemCount: kWatermarkStyleOptions.length,
                itemBuilder: (context, index) {
                  final option = kWatermarkStyleOptions[index];
                  return _StyleGridItem(
                    option: option,
                    onTap: () => _onStyleTap(context, option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleGridItem extends StatelessWidget {
  const _StyleGridItem({required this.option, required this.onTap});

  final WatermarkStyleOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _WatermarkStylePreview(type: option.type),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatermarkStylePreview extends StatelessWidget {
  const _WatermarkStylePreview({required this.type});

  final WatermarkStyleType type;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF3A3A3A),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: switch (type) {
            WatermarkStyleType.timeLocationWeather =>
              const _TimeLocationWeatherPreview(),
            WatermarkStyleType.custom => const _CustomWatermarkPreview(),
            WatermarkStyleType.engineering => const _EngineeringPreview(),
            WatermarkStyleType.attendance => const _AttendancePreview(),
            WatermarkStyleType.stopwatch => const _StopwatchPreview(),
            WatermarkStyleType.patrol => const _PatrolPreview(),
            WatermarkStyleType.property => const _PropertyPreview(),
            WatermarkStyleType.licensePlate => const _LicensePlatePreview(),
            WatermarkStyleType.brand => const _BrandPreview(),
            WatermarkStyleType.epidemic => const _EpidemicPreview(),
            WatermarkStyleType.diary => const _DiaryPreview(),
            WatermarkStyleType.onsite => const _OnsitePreview(),
          },
        ),
      ),
    );
  }
}

class _PreviewText extends StatelessWidget {
  const _PreviewText(
    this.text, {
    this.fontSize = 7,
    this.color = Colors.white,
    this.fontWeight = FontWeight.normal,
  });

  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: 1.3,
      ),
    );
  }
}

class _TimeLocationWeatherPreview extends StatelessWidget {
  const _TimeLocationWeatherPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PreviewText('11:30', fontSize: 18, fontWeight: FontWeight.w600),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PreviewText('2026.05.12 周一', fontSize: 6),
            const SizedBox(width: 4),
            Icon(Icons.wb_sunny_outlined, size: 8, color: Colors.amber.shade300),
            const _PreviewText(' 22°C', fontSize: 6),
          ],
        ),
        const _PreviewText('北京市 · 三里屯', fontSize: 6),
      ],
    );
  }
}

class _CustomWatermarkPreview extends StatelessWidget {
  const _CustomWatermarkPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        _PreviewText('经度 116.4074', fontSize: 6),
        _PreviewText('纬度 39.9042', fontSize: 6),
        _PreviewText('天气 晴 22°C', fontSize: 6),
        _PreviewText('海拔 43m', fontSize: 6),
        _PreviewText('2026.05.12 11:30', fontSize: 6),
        _PreviewText('地点 可编辑', fontSize: 6, color: Color(0xFF90CAF9)),
      ],
    );
  }
}

class _EngineeringPreview extends StatelessWidget {
  const _EngineeringPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: const Color(0xFF1677FF),
          child: const _PreviewText(
            '工程记录',
            fontSize: 7,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          color: Colors.white.withValues(alpha: 0.9),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewText('施工内容：', fontSize: 5, color: Color(0xFF333333)),
              _PreviewText('拍摄时间：11:30', fontSize: 5, color: Color(0xFF333333)),
              _PreviewText('坐标：116.40,39.90', fontSize: 5, color: Color(0xFF333333)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendancePreview extends StatelessWidget {
  const _AttendancePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const _PreviewText(
              '打卡 12:30',
              fontSize: 8,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const _PreviewText(
            '地点不可修改',
            fontSize: 6,
            color: Color(0xFF666666),
          ),
        ],
      ),
    );
  }
}

class _StopwatchPreview extends StatelessWidget {
  const _StopwatchPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        _PreviewText(
          '11:30:45',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF00E676),
        ),
        _PreviewText('.328', fontSize: 8, color: Color(0xFF00E676)),
        _PreviewText('自定义内容', fontSize: 6),
        _PreviewText('深圳市南山区', fontSize: 6),
      ],
    );
  }
}

class _PatrolPreview extends StatelessWidget {
  const _PatrolPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: const Color(0xFFFFC107),
          child: const _PreviewText(
            '执勤巡逻',
            fontSize: 7,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          color: const Color(0xFF1677FF).withValues(alpha: 0.85),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewText('工作内容：巡逻检查', fontSize: 5),
              _PreviewText('时间：11:30', fontSize: 5),
              _PreviewText('地点：深圳市', fontSize: 5),
            ],
          ),
        ),
      ],
    );
  }
}

class _PropertyPreview extends StatelessWidget {
  const _PropertyPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFF1677FF)],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PreviewText(
                '物业管理',
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(width: 4),
              ...List.generate(
                5,
                (_) => Icon(Icons.star, size: 5, color: Colors.amber.shade300),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewText('11:30  晴 22°C', fontSize: 5),
              _PreviewText('深圳市南山区', fontSize: 5),
            ],
          ),
        ),
      ],
    );
  }
}

class _LicensePlatePreview extends StatelessWidget {
  const _LicensePlatePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1677FF),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: const _PreviewText(
            '粤A·12345',
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const _PreviewText('11:30', fontSize: 6),
        const _PreviewText('深圳市南山区', fontSize: 6),
      ],
    );
  }
}

class _BrandPreview extends StatelessWidget {
  const _BrandPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const _PreviewText(
            '品牌宣传·防盗',
            fontSize: 7,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const _PreviewText('联系电话：138****8888', fontSize: 5),
        const _PreviewText('11:30  深圳市', fontSize: 5),
      ],
    );
  }
}

class _EpidemicPreview extends StatelessWidget {
  const _EpidemicPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: const Color(0xFF1677FF),
          child: const _PreviewText(
            '疫情防控',
            fontSize: 7,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          color: Colors.white.withValues(alpha: 0.9),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewText('时间：11:30', fontSize: 5, color: Color(0xFF333333)),
              _PreviewText('地点：深圳市', fontSize: 5, color: Color(0xFF333333)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiaryPreview extends StatelessWidget {
  const _DiaryPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE53935), width: 1),
              ),
              child: Icon(Icons.flag, size: 8, color: Colors.red.shade400),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: const Color(0xFFE53935),
              child: const _PreviewText(
                '民情日记',
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const _PreviewText('书记：张三', fontSize: 5),
        const _PreviewText('11:30  深圳市', fontSize: 5),
      ],
    );
  }
}

class _OnsitePreview extends StatelessWidget {
  const _OnsitePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        _PreviewText(
          '现场拍照',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFCCCCCC),
        ),
        _PreviewText('经度 116.4074', fontSize: 5, color: Color(0xFF999999)),
        _PreviewText('11:30', fontSize: 5, color: Color(0xFF999999)),
      ],
    );
  }
}
