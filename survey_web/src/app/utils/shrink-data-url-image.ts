/**
 * Downscales a data-URL / large API photo so WebView UI stays responsive.
 * Returns the original string if decode/canvas fails.
 */
export async function shrinkDataUrlImage(
  dataUrl: string,
  maxSide = 1280,
  quality = 0.6,
): Promise<string> {
  const src = (dataUrl ?? '').trim();
  if (!src.startsWith('data:image')) {
    return src;
  }

  try {
    const img = await loadImage(src);
    let width = img.naturalWidth || img.width;
    let height = img.naturalHeight || img.height;
    if (!width || !height) {
      return src;
    }

    if (width > maxSide || height > maxSide) {
      const ratio = Math.min(maxSide / width, maxSide / height);
      width = Math.round(width * ratio);
      height = Math.round(height * ratio);
    }

    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      return src;
    }
    ctx.drawImage(img, 0, 0, width, height);
    return canvas.toDataURL('image/jpeg', quality);
  } catch {
    return src;
  }
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error('image decode failed'));
    img.src = src;
  });
}
