enum RuleSetVisibility {
  private,
  public,
}

extension RuleSetVisibilityX on RuleSetVisibility {
  String get label {
    switch (this) {
      case RuleSetVisibility.private:
        return '非公開';
      case RuleSetVisibility.public:
        return '公開';
    }
  }
}
