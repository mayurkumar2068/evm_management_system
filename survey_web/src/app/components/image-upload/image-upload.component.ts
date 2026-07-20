import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  Output,
  ViewChild,
  signal,
} from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { TranslatePipe } from '../../i18n/translate.pipe';

/**
 * Compact per-row image control: opens camera or gallery, downscales the photo
 * to a sensible JPEG (keeps the base64 payload light for the WebView) and
 * shows a thumbnail with remove / re-upload affordances.
 */
@Component({
  selector: 'app-image-upload',
  standalone: true,
  imports: [
    MatIconModule,
    MatMenuModule,
    MatButtonModule,
    MatProgressSpinnerModule,
    TranslatePipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <input
      #cameraInput
      type="file"
      accept="image/*"
      capture="environment"
      hidden
      (change)="onFile($event)"
    />
    <input
      #galleryInput
      type="file"
      accept="image/*"
      hidden
      (change)="onFile($event)"
    />

    @if (processing()) {
      <div class="iu-btn iu-btn--busy">
        <mat-spinner diameter="20" strokeWidth="2" />
      </div>
    } @else if (image) {
      <div class="iu-thumb">
        <img
          [src]="image"
          alt="upload"
          loading="lazy"
          decoding="async"
          (click)="enlarge.emit(image)"
        />
        <button
          type="button"
          class="iu-thumb__remove"
          [attr.aria-label]="'common.remove' | t"
          (click)="remove()"
        >
          <mat-icon>close</mat-icon>
        </button>
      </div>
    } @else {
      <button
        type="button"
        class="iu-btn"
        [class.iu-btn--disabled]="disabled"
        [disabled]="disabled"
        [matMenuTriggerFor]="srcMenu"
        [attr.aria-label]="'img.add' | t"
      >
        <mat-icon>photo_camera</mat-icon>
      </button>
    }

    <mat-menu #srcMenu="matMenu">
      <button mat-menu-item (click)="open('camera')">
        <mat-icon>photo_camera</mat-icon>
        <span>{{ 'img.camera' | t }}</span>
      </button>
      <button mat-menu-item (click)="open('gallery')">
        <mat-icon>photo_library</mat-icon>
        <span>{{ 'img.gallery' | t }}</span>
      </button>
    </mat-menu>
  `,
  styles: [
    `
      :host {
        display: inline-flex;
      }
      .iu-btn {
        width: 44px;
        height: 44px;
        border: none;
        border-radius: 14px;
        background: var(--ec-grad-accent);
        color: #fff !important;
        display: grid;
        place-items: center;
        cursor: pointer;
        box-shadow: 0 10px 22px rgba(59, 130, 246, 0.22);
        transition: transform 0.1s ease, box-shadow 0.2s ease;
      }
      .iu-btn:active {
        transform: scale(0.96);
        box-shadow: 0 8px 18px rgba(59, 130, 246, 0.24);
      }
      .iu-btn--disabled {
        opacity: 0.5;
        cursor: not-allowed;
        box-shadow: none;
      }
      .iu-btn--busy {
        background: #eef2f0;
        cursor: default;
      }
      .iu-btn mat-icon {
        font-size: 20px;
        width: 20px;
        height: 20px;
      }
      .iu-thumb {
        position: relative;
        width: 38px;
        height: 38px;
      }
      .iu-thumb img {
        width: 38px;
        height: 38px;
        object-fit: cover;
        border-radius: 10px;
        border: 1px solid var(--ec-border);
      }
      .iu-thumb__remove {
        position: absolute;
        top: -7px;
        right: -7px;
        width: 18px;
        height: 18px;
        border-radius: 50%;
        border: none;
        background: #c2418a;
        color: #fff;
        display: grid;
        place-items: center;
        cursor: pointer;
        padding: 0;
      }
      .iu-thumb__remove mat-icon {
        font-size: 13px;
        width: 13px;
        height: 13px;
        line-height: 13px;
      }
    `,
  ],
})
export class ImageUploadComponent {
  /** Longest edge of the stored image — small enough for a fast WebView. */
  private static readonly MAX_SIDE = 1280;
  /** JPEG quality for the stored/compressed image. */
  private static readonly QUALITY = 0.6;

  @Input() image: string | null = null;
  @Input() disabled = false;

  @Output() imageChange = new EventEmitter<string | null>();
  @Output() enlarge = new EventEmitter<string>();

  /** True while a freshly picked photo is being downscaled/compressed. */
  readonly processing = signal(false);

  @ViewChild('cameraInput') private cameraInput!: ElementRef<HTMLInputElement>;
  @ViewChild('galleryInput') private galleryInput!: ElementRef<HTMLInputElement>;

  open(source: 'camera' | 'gallery'): void {
    // Prefer the native bridge inside the Flutter WebView: it captures via
    // image_picker (app cache + its own FileProvider, no MediaStore insert),
    // which avoids OEM camera-intent crashes (e.g. Vivo). Falls back to the
    // hidden <input> when running in a plain browser.
    const bridge = (window as any).AppBridge;
    if (bridge && typeof bridge.pickImage === 'function') {
      void this.openNative(bridge, source);
      return;
    }
    const input =
      source === 'camera' ? this.cameraInput : this.galleryInput;
    input.nativeElement.value = '';
    input.nativeElement.click();
  }

  private async openNative(
    bridge: any,
    source: 'camera' | 'gallery',
  ): Promise<void> {
    this.processing.set(true);
    try {
      const res = await bridge.pickImage({
        source,
        maxWidth: ImageUploadComponent.MAX_SIDE,
        quality: Math.round(ImageUploadComponent.QUALITY * 100),
      });
      if (res && res.ok && typeof res.dataUrl === 'string') {
        this.imageChange.emit(res.dataUrl);
      }
    } catch {
      // Bridge failed — fall back to the browser file input.
      const input =
        source === 'camera' ? this.cameraInput : this.galleryInput;
      input.nativeElement.value = '';
      input.nativeElement.click();
    } finally {
      this.processing.set(false);
    }
  }

  remove(): void {
    this.imageChange.emit(null);
  }

  async onFile(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) {
      return;
    }
    this.processing.set(true);
    try {
      const dataUrl = await this.compress(file);
      this.imageChange.emit(dataUrl);
    } catch {
      // Fall back to the raw file if canvas processing fails.
      const raw = await this.readAsDataUrl(file);
      this.imageChange.emit(raw);
    } finally {
      this.processing.set(false);
    }
  }

  /**
   * Downscale + JPEG-compress the picked photo so the base64 stored in the
   * form (and rendered in the WebView) stays light. Uses the fast
   * `createImageBitmap` decode path with a graceful `<img>` fallback, and
   * `canvas.toBlob` to avoid building a huge synchronous data-URL string.
   */
  private async compress(file: File): Promise<string> {
    const source = await this.decode(file);
    const { width: w0, height: h0 } = source;
    const max = ImageUploadComponent.MAX_SIDE;

    let width = w0;
    let height = h0;
    if (width > max || height > max) {
      const ratio = Math.min(max / width, max / height);
      width = Math.round(width * ratio);
      height = Math.round(height * ratio);
    }

    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      throw new Error('canvas unsupported');
    }
    ctx.drawImage(source as CanvasImageSource, 0, 0, width, height);

    // Release the decoded bitmap memory as soon as we are done drawing.
    if (typeof ImageBitmap !== 'undefined' && source instanceof ImageBitmap) {
      source.close();
    }

    return this.canvasToJpegDataUrl(canvas);
  }

  /** Prefer the GPU-friendly `createImageBitmap`, fall back to `<img>`. */
  private async decode(file: File): Promise<ImageBitmap | HTMLImageElement> {
    if (typeof createImageBitmap === 'function') {
      try {
        return await createImageBitmap(file, {
          imageOrientation: 'from-image',
        } as ImageBitmapOptions);
      } catch {
        /* fall through to the <img> path */
      }
    }
    return this.loadImage(await this.readAsDataUrl(file));
  }

  private canvasToJpegDataUrl(canvas: HTMLCanvasElement): Promise<string> {
    const quality = ImageUploadComponent.QUALITY;
    return new Promise<string>((resolve) => {
      if (canvas.toBlob) {
        canvas.toBlob(
          (blob) => {
            if (!blob) {
              resolve(canvas.toDataURL('image/jpeg', quality));
              return;
            }
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result as string);
            reader.onerror = () =>
              resolve(canvas.toDataURL('image/jpeg', quality));
            reader.readAsDataURL(blob);
          },
          'image/jpeg',
          quality,
        );
      } else {
        resolve(canvas.toDataURL('image/jpeg', quality));
      }
    });
  }

  private readAsDataUrl(file: Blob): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = () => reject(reader.error);
      reader.readAsDataURL(file);
    });
  }

  private loadImage(src: string): Promise<HTMLImageElement> {
    return new Promise<HTMLImageElement>((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error('image decode failed'));
      img.src = src;
    });
  }
}
