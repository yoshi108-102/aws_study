/**
 * Boyer-Moore-Horspool String Search Algorithm
 *
 * BMの簡略版。Good Suffix を使わず、Bad Character のみ。
 * テキストの末尾文字だけを参照してシフト量を決定する（Horspoolの特徴）。
 *
 * Returns an array of step objects for visualization.
 * Each step describes:
 *   - patternPos : パターン先頭のテキスト上の位置
 *   - comparePos : 比較中のテキスト位置
 *   - patternIdx : 比較中のパターンインデックス（右端 = m-1 から左へ）
 *   - matched     : 一致したか
 *   - shift       : シフト量（null = まだシフト前）
 *   - shiftRule   : "bad-char" | "found"
 *   - foundAt     : 発見位置（number | null）
 *   - pivotChar   : シフト判定に使われた文字（テキスト窓の末尾文字）
 */

// --------------------------------------------------------
// Horspool Bad Character (Shift) Table
// ※ BM の bad char は「ミスマッチ位置の文字」を参照するが、
//   Horspool は「窓の末尾文字」を参照する点が異なる。
// --------------------------------------------------------
export function buildHorspoolTable(pattern) {
    const m = pattern.length;
    const table = {};

    // すべての文字のデフォルトシフトはパターン長
    // パターン末尾より左の文字にシフト量を設定
    for (let i = 0; i < m - 1; i++) {
        table[pattern[i]] = m - 1 - i;
    }
    return table;
}

// --------------------------------------------------------
// Boyer-Moore-Horspool: ステップ列を返す
// --------------------------------------------------------
export function boyerMooreHorspoolSteps(text, pattern) {
    const n = text.length;
    const m = pattern.length;
    const steps = [];

    if (m === 0 || m > n) return steps;

    const shiftTable = buildHorspoolTable(pattern);

    let s = 0; // pattern の先頭位置

    while (s <= n - m) {
        const pivotChar = text[s + m - 1]; // 窓末尾の文字（シフト判定用）
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
                pivotChar,
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
                shift: shiftTable[pivotChar] ?? m,
                shiftRule: "found",
                foundAt: s,
                pivotChar,
            });
            s += shiftTable[pivotChar] ?? m;
        } else {
            // ミスマッチ記録
            steps.push({
                patternPos: s,
                comparePos: s + j,
                patternIdx: j,
                matched: false,
                shift: null,
                shiftRule: null,
                foundAt: null,
                pivotChar,
            });

            const shift = shiftTable[pivotChar] ?? m;
            steps.push({
                patternPos: s,
                comparePos: s + j,
                patternIdx: j,
                matched: false,
                shift,
                shiftRule: "bad-char",
                foundAt: null,
                pivotChar,
            });

            s += shift;
        }
    }

    return steps;
}
