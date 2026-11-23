import { fetchClient, fetchRawClient } from "./client";

export interface ReceiptItem {
  id: string;
  businessId: string;
  transactionId: string;
  originalFilename: string;
  contentType: string;
  fileSizeBytes: number;
  sha256Checksum: string;
  createdAt: string;
}

export interface ReceiptDownloadUrl {
  receiptId: string;
  url: string;
  expiresInSeconds: number;
  filename: string;
  contentType: string;
}

export class ReceiptApi {
  static async listForTransaction(transactionId: string): Promise<ReceiptItem[]> {
    return await fetchClient(`/receipts/transactions/${transactionId}`);
  }

  static async upload(transactionId: string, file: File): Promise<ReceiptItem> {
    const formData = new FormData();
    formData.append("file", file);
    const res = await fetchRawClient(`/receipts/transactions/${transactionId}`, {
      method: "POST",
      body: formData,
    });
    if (!res.ok) {
      let msg = "Failed to upload receipt";
      try {
        const err = await res.json();
        msg = err.message || msg;
      } catch {
        // ignore parse failure
      }
      throw new Error(msg);
    }
    return await res.json();
  }

  static async getDownloadUrl(receiptId: string): Promise<ReceiptDownloadUrl> {
    return await fetchClient(`/receipts/${receiptId}/download-url`);
  }

  static async downloadFile(receiptId: string, fallbackFilename: string): Promise<void> {
    const res = await fetchRawClient(`/receipts/${receiptId}/content`, {
      method: "GET",
    });
    if (!res.ok) {
      throw new Error("Failed to download receipt");
    }
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = fallbackFilename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  static async delete(receiptId: string): Promise<void> {
    await fetchClient(`/receipts/${receiptId}`, {
      method: "DELETE",
    });
  }
}
