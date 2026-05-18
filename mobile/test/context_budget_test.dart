import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/memory/context_budget.dart';

void main() {
  group('ContextBudget', () {
    test('default values', () {
      const budget = ContextBudget();
      expect(budget.maxTokens, 128000);
      expect(budget.reservedForResponse, 4096);
      expect(budget.reservedForTools, 2048);
      expect(budget.reservedForMemory, 4096);
      expect(budget.reservedForSystem, 1024);
    });

    test('availableForHistory calculation', () {
      const budget = ContextBudget();
      expect(budget.availableForHistory, 128000 - 4096 - 2048 - 4096 - 1024);
    });

    test('custom values', () {
      const budget = ContextBudget(
        maxTokens: 200000,
        reservedForResponse: 8192,
        reservedForTools: 4096,
        reservedForMemory: 8192,
        reservedForSystem: 2048,
      );
      expect(budget.maxTokens, 200000);
      expect(budget.availableForHistory, 200000 - 8192 - 4096 - 8192 - 2048);
    });
  });

  group('ContextBudgetManager', () {
    test('remainingTokens starts at maxTokens', () {
      const budget = ContextBudget(maxTokens: 128000);
      final manager = ContextBudgetManager(budget);
      expect(manager.remainingTokens, 128000);
    });

    test('canFit returns true when enough space', () {
      const budget = ContextBudget(maxTokens: 128000);
      final manager = ContextBudgetManager(budget);
      expect(manager.canFit(1000), true);
    });

    test('canFit returns false when exceeds availableForHistory', () {
      const budget = ContextBudget(maxTokens: 128000);
      final manager = ContextBudgetManager(budget);
      expect(manager.canFit(budget.availableForHistory + 1), false);
    });

    test('allocate reduces remaining', () {
      const budget = ContextBudget(maxTokens: 128000);
      final manager = ContextBudgetManager(budget);
      final before = manager.remainingTokens;
      manager.allocate(10000);
      expect(manager.remainingTokens, lessThan(before));
      expect(manager.usedTokens, 10000);
    });
  });
}
