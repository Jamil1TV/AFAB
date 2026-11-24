"use client";

import React, { useState } from "react";
import { Check, Copy } from "lucide-react";

function renderInline(text: string): React.ReactNode[] {
  const parts: React.ReactNode[] = [];
  const regex = /(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)/g;
  let lastIndex = 0;
  let match: RegExpExecArray | null;
  let key = 0;

  while ((match = regex.exec(text)) !== null) {
    if (match.index > lastIndex) {
      parts.push(text.slice(lastIndex, match.index));
    }
    const token = match[0];
    if (token.startsWith("**") && token.endsWith("**")) {
      parts.push(
        <strong key={key++} className="font-semibold text-gray-950 dark:text-white">
          {token.slice(2, -2)}
        </strong>
      );
    } else if (token.startsWith("`") && token.endsWith("`")) {
      parts.push(
        <code
          key={key++}
          className="px-1.5 py-0.5 rounded-md bg-[var(--primary)]/10 border border-[var(--primary)]/20 font-mono text-[12px] text-[var(--primary)]"
        >
          {token.slice(1, -1)}
        </code>
      );
    } else if (token.startsWith("*") && token.endsWith("*")) {
      parts.push(<em key={key++} className="italic text-gray-700 dark:text-gray-300">{token.slice(1, -1)}</em>);
    }
    lastIndex = match.index + token.length;
  }

  if (lastIndex < text.length) {
    parts.push(text.slice(lastIndex));
  }
  return parts;
}

function CodeBlock({ language, code }: { language: string; code: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1800);
    } catch {
      // Clipboard unavailable
    }
  };

  return (
    <div
      dir="ltr"
      className="my-3 overflow-hidden rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-950 text-gray-100 shadow-xs"
    >
      <div className="flex items-center justify-between px-3.5 py-1.5 bg-gray-900 border-b border-gray-800 text-[11px]">
        <span className="font-mono uppercase tracking-wider text-gray-400">
          {language || "code"}
        </span>
        <button
          type="button"
          onClick={handleCopy}
          className="inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-gray-300 hover:bg-white/10 hover:text-white transition-colors"
        >
          {copied ? (
            <>
              <Check className="h-3 w-3 text-emerald-400" />
              <span className="text-emerald-400">Copied</span>
            </>
          ) : (
            <>
              <Copy className="h-3 w-3" />
              <span>Copy</span>
            </>
          )}
        </button>
      </div>
      <pre className="overflow-x-auto p-3.5 text-xs font-mono leading-relaxed">
        <code>{code}</code>
      </pre>
    </div>
  );
}

function splitTableRow(line: string): string[] {
  const trimmed = line.trim().replace(/^\|/, "").replace(/\|$/, "");
  return trimmed.split("|").map((cell) => cell.trim());
}

function isTableSeparator(line: string): boolean {
  const trimmed = line.trim();
  if (!trimmed.includes("|") || !trimmed.includes("-")) return false;
  const cells = splitTableRow(trimmed);
  return cells.length > 0 && cells.every((c) => /^:?-{2,}:?$/.test(c));
}

export function CopilotMarkdown({
  content,
  isStreaming = false,
}: {
  content: string;
  isStreaming?: boolean;
}) {
  const lines = (content || "").replace(/\r\n/g, "\n").split("\n");

  type BlockItem =
    | { kind: "code"; key: number; language: string; code: string }
    | { kind: "hr"; key: number }
    | { kind: "heading"; key: number; level: number; text: string }
    | { kind: "blockquote"; key: number; lines: string[] }
    | { kind: "table"; key: number; headers: string[]; rows: string[][] }
    | { kind: "ul"; key: number; items: string[] }
    | { kind: "ol"; key: number; items: string[] }
    | { kind: "p"; key: number; text: string };

  const parsedBlocks: BlockItem[] = [];
  let i = 0;
  let blockKey = 0;

  while (i < lines.length) {
    const line = lines[i];
    const trimmed = line.trim();

    if (!trimmed) {
      i++;
      continue;
    }

    if (trimmed.startsWith("```")) {
      const language = trimmed.slice(3).trim();
      const codeLines: string[] = [];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith("```")) {
        codeLines.push(lines[i]);
        i++;
      }
      if (i < lines.length) i++;
      parsedBlocks.push({ kind: "code", key: blockKey++, language, code: codeLines.join("\n") });
      continue;
    }

    if (/^(-{3,}|\*{3,})$/.test(trimmed)) {
      parsedBlocks.push({ kind: "hr", key: blockKey++ });
      i++;
      continue;
    }

    const headingMatch = trimmed.match(/^(#{1,3})\s+(.*)$/);
    if (headingMatch) {
      parsedBlocks.push({
        kind: "heading",
        key: blockKey++,
        level: headingMatch[1].length,
        text: headingMatch[2],
      });
      i++;
      continue;
    }

    if (trimmed.startsWith(">")) {
      const quoteLines: string[] = [];
      while (i < lines.length && lines[i].trim().startsWith(">")) {
        quoteLines.push(lines[i].trim().replace(/^>\s?/, ""));
        i++;
      }
      parsedBlocks.push({ kind: "blockquote", key: blockKey++, lines: quoteLines });
      continue;
    }

    if (
      trimmed.includes("|") &&
      i + 1 < lines.length &&
      isTableSeparator(lines[i + 1])
    ) {
      const headers = splitTableRow(trimmed);
      i += 2;
      const rows: string[][] = [];
      while (
        i < lines.length &&
        lines[i].trim().includes("|") &&
        !lines[i].trim().startsWith("```")
      ) {
        rows.push(splitTableRow(lines[i]));
        i++;
      }
      parsedBlocks.push({ kind: "table", key: blockKey++, headers, rows });
      continue;
    }

    if (/^[-*•]\s+/.test(trimmed)) {
      const items: string[] = [];
      while (i < lines.length && /^[-*•]\s+/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^[-*•]\s+/, ""));
        i++;
      }
      parsedBlocks.push({ kind: "ul", key: blockKey++, items });
      continue;
    }

    if (/^\d+\.\s+/.test(trimmed)) {
      const items: string[] = [];
      while (i < lines.length && /^\d+\.\s+/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^\d+\.\s+/, ""));
        i++;
      }
      parsedBlocks.push({ kind: "ol", key: blockKey++, items });
      continue;
    }

    const paraLines: string[] = [trimmed];
    i++;
    while (
      i < lines.length &&
      lines[i].trim() !== "" &&
      !/^(#{1,3}\s+|[-*•]\s+|\d+\.\s+|```|>\s?|(-{3,}|\*{3,})$)/.test(lines[i].trim()) &&
      !(lines[i].trim().includes("|") && i + 1 < lines.length && isTableSeparator(lines[i + 1]))
    ) {
      paraLines.push(lines[i].trim());
      i++;
    }
    parsedBlocks.push({ kind: "p", key: blockKey++, text: paraLines.join(" ") });
  }

  return (
    <div className="space-y-2 text-[14.5px] leading-[1.72] text-gray-800 dark:text-gray-200">
      {parsedBlocks.map((block, idx) => {
        const isLast = idx === parsedBlocks.length - 1;
        const cursor = isStreaming && isLast ? (
          <span className="ai-streaming-cursor" aria-hidden="true" />
        ) : null;

        switch (block.kind) {
          case "code":
            return (
              <React.Fragment key={block.key}>
                <CodeBlock language={block.language} code={block.code} />
                {cursor}
              </React.Fragment>
            );

          case "hr":
            return (
              <React.Fragment key={block.key}>
                <hr className="my-3.5 border-gray-200 dark:border-gray-800" />
                {cursor}
              </React.Fragment>
            );

          case "heading": {
            const headingCls =
              block.level === 1
                ? "mt-4 mb-1.5 text-base font-bold tracking-tight text-gray-950 dark:text-white"
                : block.level === 2
                ? "mt-3.5 mb-1 text-[15px] font-bold tracking-tight text-gray-900 dark:text-white"
                : "mt-3 mb-1 text-sm font-bold text-gray-900 dark:text-gray-100";
            return (
              <h4 key={block.key} className={headingCls}>
                {renderInline(block.text)}
                {cursor}
              </h4>
            );
          }

          case "blockquote":
            return (
              <blockquote
                key={block.key}
                className="border-s-2 border-[var(--primary)] bg-[var(--primary)]/[0.05] dark:bg-[var(--primary)]/10 rounded-e-xl px-3.5 py-2.5 my-2.5 text-[13.5px] text-gray-700 dark:text-gray-200 leading-relaxed"
              >
                {block.lines.map((qLine, qIdx) => (
                  <p key={qIdx} className={qIdx > 0 ? "mt-1" : ""}>
                    {renderInline(qLine)}
                    {qIdx === block.lines.length - 1 ? cursor : null}
                  </p>
                ))}
              </blockquote>
            );

          case "table":
            return (
              <div
                key={block.key}
                className="my-3 overflow-x-auto rounded-xl border border-[var(--border)] bg-[var(--surface-inset)] shadow-xs"
              >
                <table className="w-full text-start text-xs tabular-nums">
                  <thead className="border-b border-gray-200 dark:border-gray-800 bg-gray-50/90 dark:bg-white/[0.03] text-[11px] font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                    <tr>
                      {block.headers.map((h, hIdx) => (
                        <th key={hIdx} className="px-3.5 py-2.5 text-start whitespace-nowrap">
                          {renderInline(h)}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800/60">
                    {block.rows.map((row, rIdx) => (
                      <tr
                        key={rIdx}
                        className="hover:bg-[var(--primary)]/5 dark:hover:bg-white/[0.02] transition-colors"
                      >
                        {block.headers.map((_, cIdx) => (
                          <td
                            key={cIdx}
                            className="px-3.5 py-2.5 text-gray-700 dark:text-gray-200 whitespace-nowrap"
                          >
                            {renderInline(row[cIdx] ?? "")}
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
                {cursor}
              </div>
            );

          case "ul":
            return (
              <ul key={block.key} className="my-2 space-y-1.5 ps-5 list-disc marker:text-[var(--primary)]">
                {block.items.map((item, idxItem) => (
                  <li key={idxItem} className="leading-[1.7] ps-1">
                    {renderInline(item)}
                    {idxItem === block.items.length - 1 ? cursor : null}
                  </li>
                ))}
              </ul>
            );

          case "ol":
            return (
              <ol key={block.key} className="my-2 space-y-1.5 ps-5 list-decimal marker:text-[var(--primary)] marker:font-semibold">
                {block.items.map((item, idxItem) => (
                  <li key={idxItem} className="leading-[1.7] ps-1">
                    {renderInline(item)}
                    {idxItem === block.items.length - 1 ? cursor : null}
                  </li>
                ))}
              </ol>
            );

          case "p":
          default:
            return (
              <p key={block.key} className="leading-[1.72]">
                {renderInline(block.text)}
                {cursor}
              </p>
            );
        }
      })}
      {parsedBlocks.length === 0 && isStreaming && (
        <span className="ai-streaming-cursor" aria-hidden="true" />
      )}
    </div>
  );
}
