import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_master.dart';
import '../../providers/food_master_provider.dart';

class FoodEditDialog extends ConsumerStatefulWidget {
  final FoodMaster? initialFood;

  const FoodEditDialog({super.key, this.initialFood});

  static Future<FoodMaster?> show(BuildContext context, {FoodMaster? food}) {
    return showDialog<FoodMaster>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FoodEditDialog(initialFood: food),
    );
  }

  @override
  ConsumerState<FoodEditDialog> createState() => _FoodEditDialogState();
}

class _FoodEditDialogState extends ConsumerState<FoodEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _baseAmountController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;

  late FoodUnit _selectedUnit;
  late String _selectedCategory;

  static const List<String> _categories = [
    '肉類',
    '加工肉',
    '魚介類',
    '卵・大豆類',
    '主食・穀物',
    '野菜類',
    'きのこ・海藻',
    '果物',
    '乳製品・サプリ',
    '油脂・調味料',
    'その他',
  ];

  bool get _isEditing => widget.initialFood != null;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFood;
    _nameController = TextEditingController(text: f?.name ?? '');
    _brandController = TextEditingController(text: f?.brand ?? '');
    _baseAmountController = TextEditingController(
      text: f != null
          ? (f.baseAmount == f.baseAmount.toInt()
              ? f.baseAmount.toInt().toString()
              : f.baseAmount.toString())
          : '100',
    );
    _caloriesController = TextEditingController(
      text: f != null ? f.calories.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '',
    );
    _proteinController = TextEditingController(
      text: f != null ? f.protein.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '',
    );
    _fatController = TextEditingController(
      text: f != null ? f.fat.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '',
    );
    _carbsController = TextEditingController(
      text: f != null ? f.carbs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '',
    );

    _selectedUnit = f?.unit ?? FoodUnit.g;
    _selectedCategory = f?.category ?? '肉類';
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'その他';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _baseAmountController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final brand = _brandController.text.trim().isEmpty ? null : _brandController.text.trim();
    final baseAmount = double.tryParse(_baseAmountController.text.trim()) ?? 100.0;
    final calories = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    final protein = double.tryParse(_proteinController.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;

    final FoodMaster savedFood;
    if (_isEditing) {
      savedFood = widget.initialFood!.copyWith(
        name: name,
        brand: brand,
        baseAmount: baseAmount,
        unit: _selectedUnit,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        category: _selectedCategory,
        isCustom: true,
      );
      ref.read(foodMasterProvider.notifier).updateFood(savedFood);
    } else {
      savedFood = FoodMaster(
        id: 'custom-food-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        brand: brand,
        baseAmount: baseAmount,
        unit: _selectedUnit,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        category: _selectedCategory,
        isCustom: true,
      );
      ref.read(foodMasterProvider.notifier).addFood(savedFood);
    }

    Navigator.of(context).pop(savedFood);
  }

  void _onDelete() {
    if (widget.initialFood == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('食材の削除'),
        content: Text('「${widget.initialFood!.name}」をライブラリから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              ref.read(foodMasterProvider.notifier).deleteFood(widget.initialFood!.id);
              Navigator.of(ctx).pop(); // 確認ダイアログを閉じる
              Navigator.of(context).pop(); // 編集ダイアログを閉じる
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isEditing ? Icons.tune : Icons.add_circle_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(_isEditing ? '食材・栄養価の調整' : '新規食材の登録'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '食材・食品名 *',
                    hintText: '例: 鶏むね肉（皮なし）, プロテインバー',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return '食品名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'カテゴリ',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'メーカー等',
                          hintText: '任意',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _baseAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '基準分量 *',
                          hintText: '例: 100',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num <= 0) return '数値を入力';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: DropdownButtonFormField<FoodUnit>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: '単位',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: FoodUnit.g, child: Text('g (グラム)')),
                          DropdownMenuItem(value: FoodUnit.ml, child: Text('ml (ミリリットル)')),
                          DropdownMenuItem(value: FoodUnit.piece, child: Text('個')),
                          DropdownMenuItem(value: FoodUnit.serving, child: Text('食 / 杯')),
                          DropdownMenuItem(value: FoodUnit.tablespoon, child: Text('大さじ')),
                          DropdownMenuItem(value: FoodUnit.teaspoon, child: Text('小さじ')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '基準分量あたりの栄養素',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _caloriesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'エネルギー (kcal) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    final num = double.tryParse(val ?? '');
                    if (num == null || num < 0) return '正の数値を入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _proteinController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'P (g) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num < 0) return '数値を入力';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _fatController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'F (g) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num < 0) return '数値を入力';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _carbsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'C (g) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num < 0) return '数値を入力';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton.icon(
            onPressed: _onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('削除'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton.icon(
          onPressed: _onSave,
          icon: const Icon(Icons.save),
          label: Text(_isEditing ? '更新する' : '登録する'),
        ),
      ],
    );
  }
}
