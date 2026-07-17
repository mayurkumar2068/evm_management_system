import { Coordinates } from '../models/location.model';

export function staticMapImageUrl(lat: number, lng: number, width = 520, height = 200): string {
  return (
    'https://staticmap.openstreetmap.de/staticmap.php' +
    `?center=${lat},${lng}&zoom=15&size=${width}x${height}` +
    `&markers=${lat},${lng},red-pushpin`
  );
}

export function openMapDirections(
  destination: Coordinates,
  origin?: Coordinates | null,
  label = 'मतदान केंद्र',
): void {
  const dest = `${destination.latitude},${destination.longitude}`;
  let url: string;
  if (origin) {
    url =
      'https://www.google.com/maps/dir/?api=1' +
      `&origin=${origin.latitude},${origin.longitude}` +
      `&destination=${dest}&travelmode=driving`;
  } else {
    url = `https://www.google.com/maps/dir/?api=1&destination=${dest}&travelmode=driving`;
  }
  const opened = window.open(url, '_blank');
  if (!opened) {
    window.location.href = `geo:${dest}?q=${dest}(${encodeURIComponent(label)})`;
  }
}
