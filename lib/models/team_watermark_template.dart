enum TeamWatermarkTemplateCategory {
  construction,
  general,
}

class TeamWatermarkTemplate {
  const TeamWatermarkTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.usageCountLabel,
    required this.category,
    required this.previewTemplateId,
    this.usedByMe = false,
  });

  final String id;
  final String title;
  final String description;
  final String usageCountLabel;
  final TeamWatermarkTemplateCategory category;
  final String previewTemplateId;
  final bool usedByMe;
}

const kTeamWatermarkTemplateCategories = [
  '我用过',
  '全部模板',
  '建筑工程',
  '通用模板',
];

const List<TeamWatermarkTemplate> kTeamWatermarkTemplates = [
  TeamWatermarkTemplate(
    id: 'before_construction',
    title: '施工前',
    description: '适用于施工前场...',
    usageCountLabel: '16万人在用',
    category: TeamWatermarkTemplateCategory.construction,
    previewTemplateId: 'classic',
    usedByMe: true,
  ),
  TeamWatermarkTemplate(
    id: 'project_acceptance',
    title: '工程验收',
    description: '适用于工程验收...',
    usageCountLabel: '7万人在用',
    category: TeamWatermarkTemplateCategory.construction,
    previewTemplateId: 'panel',
    usedByMe: true,
  ),
  TeamWatermarkTemplate(
    id: 'during_construction',
    title: '施工中',
    description: '适用于施工过程...',
    usageCountLabel: '26万人在用',
    category: TeamWatermarkTemplateCategory.construction,
    previewTemplateId: 'classic',
  ),
  TeamWatermarkTemplate(
    id: 'preset_construction_content',
    title: '预设施工内容',
    description: '适用于施工过程...',
    usageCountLabel: '1万人在用',
    category: TeamWatermarkTemplateCategory.construction,
    previewTemplateId: 'panel',
  ),
  TeamWatermarkTemplate(
    id: 'after_construction',
    title: '施工后',
    description: '适用于施工过场...',
    usageCountLabel: '2万人在用',
    category: TeamWatermarkTemplateCategory.construction,
    previewTemplateId: 'minimal',
  ),
  TeamWatermarkTemplate(
    id: 'general_classic',
    title: '经典水印',
    description: '适用于日常记录...',
    usageCountLabel: '9万人在用',
    category: TeamWatermarkTemplateCategory.general,
    previewTemplateId: 'classic',
  ),
  TeamWatermarkTemplate(
    id: 'general_panel',
    title: '卡片水印',
    description: '适用于卡片式记录...',
    usageCountLabel: '5万人在用',
    category: TeamWatermarkTemplateCategory.general,
    previewTemplateId: 'panel',
  ),
  TeamWatermarkTemplate(
    id: 'general_minimal',
    title: '极简水印',
    description: '适用于简洁定位...',
    usageCountLabel: '3万人在用',
    category: TeamWatermarkTemplateCategory.general,
    previewTemplateId: 'minimal',
  ),
];
