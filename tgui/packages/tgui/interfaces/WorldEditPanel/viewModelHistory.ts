import { toneForHistoryResult } from './helpers';
import type { HistoryEntry } from './types';

type HistoryMetrics = {
  total: number;
  good: number;
  average: number;
  bad: number;
};

const getHistoryMetrics = (
  historyEntries: HistoryEntry[] = [],
): HistoryMetrics =>
  historyEntries.reduce(
    (acc, entry) => {
      const tone = toneForHistoryResult(entry.result);
      acc.total += 1;
      if (tone === 'good') {
        acc.good += 1;
      } else if (tone === 'average') {
        acc.average += 1;
      } else if (tone === 'bad') {
        acc.bad += 1;
      }
      return acc;
    },
    {
      total: 0,
      good: 0,
      average: 0,
      bad: 0,
    },
  );

export { getHistoryMetrics };
export type { HistoryMetrics };
