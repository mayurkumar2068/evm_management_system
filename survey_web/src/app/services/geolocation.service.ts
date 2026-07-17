import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { Coordinates } from '../models/location.model';

export type GeolocationErrorKind =
  | 'unsupported'
  | 'permission-denied'
  | 'unavailable'
  | 'timeout';

export class GeolocationError extends Error {
  constructor(
    public readonly kind: GeolocationErrorKind,
    message: string,
  ) {
    super(message);
    this.name = 'GeolocationError';
  }
}

/**
 * Thin wrapper over the browser Geolocation API exposed as an Observable so
 * components can subscribe with loading / error handling. Works inside
 * InAppWebView provided the host app grants location permission.
 */
@Injectable({ providedIn: 'root' })
export class GeolocationService {
  getCurrentPosition(): Observable<Coordinates> {
    return new Observable<Coordinates>((subscriber) => {
      if (!('geolocation' in navigator)) {
        subscriber.error(
          new GeolocationError(
            'unsupported',
            'इस डिवाइस पर लोकेशन उपलब्ध नहीं है।',
          ),
        );
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          subscriber.next({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy,
          });
          subscriber.complete();
        },
        (error) => subscriber.error(this.mapError(error)),
        {
          enableHighAccuracy: true,
          timeout: 15000,
          maximumAge: 0,
        },
      );
    });
  }

  private mapError(error: GeolocationPositionError): GeolocationError {
    switch (error.code) {
      case error.PERMISSION_DENIED:
        return new GeolocationError(
          'permission-denied',
          'लोकेशन की अनुमति अस्वीकृत कर दी गई है।',
        );
      case error.POSITION_UNAVAILABLE:
        return new GeolocationError(
          'unavailable',
          'लोकेशन प्राप्त नहीं हो सकी।',
        );
      case error.TIMEOUT:
        return new GeolocationError(
          'timeout',
          'लोकेशन प्राप्त करने में समय अधिक लग रहा है।',
        );
      default:
        return new GeolocationError('unavailable', error.message);
    }
  }
}
