/**
 * Boyer-Moore String Search Algorithm
 *
 * Returns an array of step objects for visualization.
 * Each step describes:
 *   - patternPos : 現在のパターン開始位置（テキスト上）
 *   - comparePos : 比較中のテキスト位置
 *   - patternIdx : 比較中のパターン INDEX（右端から）
 *   - matched     : 一致したか
 *   - shift       : このステップで何文字シフトするか（null = まだシフト前）
 *   - shiftRule   : "bad-char" | "good-suffix" | "found"
 *   - foundAt     : 発見位置（number | null）
 */

// --------------------------------------------------------
// Bad Character Table
// --------------------------------------------------------
function buildBadCharTable(pattern) {
  const table = {};
  for (let i = 0; i < pattern.length - 1; i++) {
    table[pattern[i]] = pattern.length - 1 - i;
  }
  return table;
}

// --------------------------------------------------------
// Good Suffix Table
// --------------------------------------------------------
function buildGoodSuffixTable(pattern) {
  const m = pattern.length;
  const shift = new Array(m + 1).fill(m);
  const border = new Array(m + 1).fill(0);

  // Phase 1: 強い好接尾辞
  let i = m;
  let j = m + 1;
  border[i] = j;
  while (i > 0) {
    while (j <= m && pattern[i - 1] !== pattern[j - 1]) {
      if (shift[j] === m) shift[j] = j - i;
      j = border[j];
    }
    i--;
    j--;
    border[i] = j;
  }

  // Phase 2: 弱い好接尾辞（プレフィックスが接尾辞に一致）
  j = border[0];
  for (i = 0; i <= m; i++) {
    if (shift[i] === m) shift[i] = j;
    if (i === j) j = border[j];
  }

  return shift;
}

// --------------------------------------------------------
// Boyer-Moore: ステップ列を返す
// --------------------------------------------------------
export function boyerMooreSteps(text, pattern) {
  const n = text.length;
  const m = pattern.length;
  const steps = [];

  if (m === 0 || m > n) return steps;

  const badChar = buildBadCharTable(pattern);
  const goodSuffix = buildGoodSuffixTable(pattern);

  let s = 0; // pattern の先頭がテキストのどこにあるか

  while (s <= n - m) {
    let j = m - 1;

    // 右から左へ比較
    while (j >= 0 && pattern[j] === text[s + j]) {
      steps.push({
        patternPos: s,
        comparePos: s + j,
        patternIdx: j,
        matched: true,
        shift: null,
        shiftRule: null,
        foundAt: null,
      });
      j--;
    }

    if (j < 0) {
      // 全文字一致 → 発見！
      steps.push({
        patternPos: s,
        comparePos: s,
        patternIdx: 0,
        matched: true,
        shift: goodSuffix[0],
        shiftRule: "found",
        foundAt: s,
      });
      s += goodSuffix[0];
    } else {
      // ミスマッチ
      steps.push({
        patternPos: s,
        comparePos: s + j,
        patternIdx: j,
        matched: false,
        shift: null,
        shiftRule: null,
        foundAt: null,
      });

      const bcShift = badChar[text[s + j]] ?? m;
      const gsShift = goodSuffix[j + 1];
      const shift = Math.max(bcShift, gsShift);
      const rule = bcShift >= gsShift ? "bad-char" : "good-suffix";

      steps.push({
        patternPos: s,
        comparePos: s + j,
        patternIdx: j,
        matched: false,
        shift,
        shiftRule: rule,
        foundAt: null,
        badCharShift: bcShift,
        goodSuffixShift: gsShift,
      });

      s += shift;
    }
  }

  return steps;
}

export { buildBadCharTable, buildGoodSuffixTable };
