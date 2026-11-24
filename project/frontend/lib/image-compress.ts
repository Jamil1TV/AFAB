/**
 * Compresses large camera/receipt photos client-side before uploading to MinIO staging
 * and sending to local gemma4:e4b vision inference (keeps dimensions <= 1024px for fast 8GB VRAM inference).
 * Non-image files (PDF, XLSX, CSV, TXT, JSON, MD) are returned untouched.
 */
export async function compressImageFile(
  file: File,
  maxDimension = 1024,
  quality = 0.85
): Promise<File> {
  if (!file.type.startsWith("image/")) {
    return file;
  }

  return new Promise((resolve) => {
    const objectUrl = URL.createObjectURL(file);
    const img = new Image();

    img.onload = () => {
      try {
        const { naturalWidth, naturalHeight } = img;
        if (!naturalWidth || !naturalHeight) {
          URL.revokeObjectURL(objectUrl);
          resolve(file);
          return;
        }

        const needsResize = naturalWidth > maxDimension || naturalHeight > maxDimension;
        if (!needsResize && file.size <= 1.2 * 1024 * 1024) {
          URL.revokeObjectURL(objectUrl);
          resolve(file);
          return;
        }

        const scale = Math.min(1, maxDimension / Math.max(naturalWidth, naturalHeight));
        const targetW = Math.max(1, Math.round(naturalWidth * scale));
        const targetH = Math.max(1, Math.round(naturalHeight * scale));

        const canvas = document.createElement("canvas");
        canvas.width = targetW;
        canvas.height = targetH;
        const ctx = canvas.getContext("2d");
        if (!ctx) {
          URL.revokeObjectURL(objectUrl);
          resolve(file);
          return;
        }
        ctx.drawImage(img, 0, 0, targetW, targetH);

        canvas.toBlob(
          (blob) => {
            URL.revokeObjectURL(objectUrl);
            if (!blob || blob.size >= file.size) {
              resolve(file);
              return;
            }
            const cleanBase = file.name.replace(/\.[^.]+$/, "");
            const compressed = new File([blob], `${cleanBase}.jpg`, {
              type: "image/jpeg",
              lastModified: Date.now(),
            });
            resolve(compressed);
          },
          "image/jpeg",
          quality
        );
      } catch {
        URL.revokeObjectURL(objectUrl);
        resolve(file);
      }
    };

    img.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      resolve(file);
    };

    img.src = objectUrl;
  });
}
