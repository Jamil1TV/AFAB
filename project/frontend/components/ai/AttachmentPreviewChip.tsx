"use client";

import { useEffect, useState } from "react";
import { FileSpreadsheet, FileText, Image as ImageIcon, X } from "lucide-react";
import { AiAttachmentItem, AiService } from "@/lib/api/ai";

interface AttachmentPreviewChipProps {
  attachment: AiAttachmentItem;
  localPreviewUrl?: string;
  onRemove?: () => void;
  compact?: boolean;
}

function formatBytes(bytes: number): string {
  if (!bytes || bytes <= 0) return "";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function AttachmentPreviewChip({
  attachment,
  localPreviewUrl,
  onRemove,
  compact = false,
}: AttachmentPreviewChipProps) {
  const isImage =
    attachment.kind === "IMAGE" || attachment.contentType?.startsWith("image/");
  const isSpreadsheet =
    attachment.contentType?.includes("spreadsheet") ||
    attachment.originalFilename?.toLowerCase().endsWith(".xlsx") ||
    attachment.originalFilename?.toLowerCase().endsWith(".csv");

  const [fetchedUrl, setFetchedUrl] = useState<string | null>(null);

  useEffect(() => {
    if (!isImage || localPreviewUrl || !attachment.id) return;
    let active = true;
    let createdUrl: string | null = null;

    AiService.fetchAttachmentPreviewUrl(attachment.id)
      .then((url) => {
        if (!active) {
          URL.revokeObjectURL(url);
          return;
        }
        createdUrl = url;
        setFetchedUrl(url);
      })
      .catch(() => {});

    return () => {
      active = false;
      if (createdUrl) {
        URL.revokeObjectURL(createdUrl);
      }
    };
  }, [isImage, localPreviewUrl, attachment.id]);

  const thumbUrl = localPreviewUrl || fetchedUrl;

  return (
    <div
      className={`group inline-flex items-center gap-2 rounded-xl border border-gray-200/90 dark:border-gray-800 bg-[var(--surface-inset)] ${
        compact ? "px-2 py-1 text-[11px]" : "px-2.5 py-1.5 text-xs"
      } max-w-[240px]`}
    >
      {isImage && thumbUrl ? (
        <img
          src={thumbUrl}
          alt={attachment.originalFilename}
          className="h-7 w-7 rounded-lg object-cover shrink-0 border border-gray-200 dark:border-gray-700"
        />
      ) : (
        <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-[var(--primary)]/10 text-[var(--primary)]">
          {isImage ? (
            <ImageIcon className="h-3.5 w-3.5" />
          ) : isSpreadsheet ? (
            <FileSpreadsheet className="h-3.5 w-3.5" />
          ) : (
            <FileText className="h-3.5 w-3.5" />
          )}
        </div>
      )}

      <div className="min-w-0 flex-1">
        <p className="truncate font-semibold text-gray-800 dark:text-gray-200 leading-tight">
          {attachment.originalFilename}
        </p>
        {attachment.fileSizeBytes > 0 && (
          <p className="text-[10px] text-gray-500 dark:text-gray-400">
            {formatBytes(attachment.fileSizeBytes)}
          </p>
        )}
      </div>

      {onRemove && (
        <button
          type="button"
          onClick={onRemove}
          className="rounded-md p-0.5 text-gray-400 hover:bg-red-500/10 hover:text-red-500 transition-colors shrink-0"
          aria-label="Remove attachment"
        >
          <X className="h-3.5 w-3.5" />
        </button>
      )}
    </div>
  );
}
