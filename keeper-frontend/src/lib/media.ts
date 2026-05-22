import { configuredBaseUrl } from '@/lib/api';

function stripDataUrlPrefix(value: string) {
  const commaIndex = value.indexOf(',');
  return commaIndex >= 0 ? value.slice(commaIndex + 1) : value;
}

function normalizePossiblyHexEncodedBase64(value: string) {
  try {
    const decoded = atob(value);
    if (!decoded.startsWith('\\x')) {
      return null;
    }

    const hex = decoded.slice(2);
    let binary = '';
    for (let index = 0; index < hex.length; index += 2) {
      binary += String.fromCharCode(parseInt(hex.slice(index, index + 2), 16));
    }

    return `data:image/png;base64,${btoa(binary)}`;
  } catch {
    return null;
  }
}

export function resolveMediaSource(value?: string | null) {
  if (!value) {
    return '';
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return '';
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('data:')) {
    return trimmed;
  }

  const normalizedHexEncoded = normalizePossiblyHexEncodedBase64(trimmed);
  if (normalizedHexEncoded) {
    return normalizedHexEncoded;
  }

  if (!trimmed.includes('/') && !trimmed.includes('\\') && !trimmed.includes('.')) {
    return `data:image/png;base64,${stripDataUrlPrefix(trimmed)}`;
  }

  try {
    const origin = new URL(configuredBaseUrl).origin;
    return `${origin}${trimmed.startsWith('/') ? '' : '/'}${trimmed}`;
  } catch {
    return `http://localhost:5247${trimmed.startsWith('/') ? '' : '/'}${trimmed}`;
  }
}

export function readFileAsDataUrl(file: File) {
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ''));
    reader.onerror = () => reject(reader.error || new Error(`Unable to read ${file.name}.`));
    reader.readAsDataURL(file);
  });
}

export async function readFilesAsDataUrls(files: File[]) {
  return Promise.all(files.map(readFileAsDataUrl));
}
