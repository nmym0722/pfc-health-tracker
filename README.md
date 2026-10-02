# PFC Health Tracker

食べたもののPFCバランス（タンパク質・脂質・炭水化物）および総摂取カロリーを計算・記録し、健康管理をサポートするモバイルアプリケーションです。

## 技術スタック
- **Framework**: Expo (React Native)
- **Language**: TypeScript
- **State Management / Storage**: 検討中 (AsyncStorage / SQLite / Supabase など)
- **UI & Icons**: テーマ適合ベクターアイコン (Ionicons等) ※絵文字非使用

## 主な想定機能
1. **食事入力・記録機能**
   - 食品名、グラム数（または分量）、PFC・カロリーの手動登録
   - お気に入り・よく食べる食品の登録
2. **PFCバランス・カロリー自動計算**
   - タンパク質 (Protein: 4kcal/g)
   - 脂質 (Fat: 9kcal/g)
   - 炭水化物 (Carbohydrate: 4kcal/g)
   - 1日の目標摂取カロリーおよびPFC比率との対比・可視化
3. **健康管理・ダッシュボード**
   - 日別・週別の推移グラフ
   - 目標達成度のプログレス表示
