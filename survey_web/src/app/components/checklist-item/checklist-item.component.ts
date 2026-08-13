import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  OnChanges,
  Output,
  SimpleChanges,
  inject,
} from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

import { ImageUploadComponent } from '../image-upload/image-upload.component';
import { TranslatePipe } from '../../i18n/translate.pipe';
import { SurveyQuestion } from '../../models/survey.model';

type AnswerValue = string | null;

/**
 * One survey question row rendered from API metadata.
 *
 * Choice questions use their `OPTIONS` list, while text questions render a
 * text/number field based on the question type. Photo capture is driven by the
 * question metadata instead of hardcoded Yes/No behavior.
 */
@Component({
  selector: 'app-checklist-item',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    ImageUploadComponent,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    TranslatePipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div
      class="ci"
      [class.ci--compact]="compact"
      [class.ci--answered]="hasAnswer"
    >
      <div class="ci__top">
        @if (!compact) {
          <span class="ci__idx">{{ index + 1 }}</span>
        }
        <div class="ci__head">
          <p class="ci__title">{{ titleFor(question) }}</p>
          @if (descriptionFor(question)) {
            <p class="ci__desc">{{ descriptionFor(question) }}</p>
          }
        </div>
      </div>

      <div class="ci__body" [formGroup]="group">
        @if (isChoiceQuestion(question)) {
          @if (usesSelect(question)) {
            <mat-form-field
              appearance="outline"
              class="ci__field"
              subscriptSizing="dynamic"
            >
              <mat-select
                formControlName="answerValue"
                [placeholder]="'chk.answer.selectPlaceholder' | t"
                (selectionChange)="setAnswer($event.value)"
              >
                <mat-option value="">
                  {{ 'chk.answer.selectPlaceholder' | t }}
                </mat-option>
                @for (option of question.options; track option.value) {
                  <mat-option [value]="option.value">{{ option.text }}</mat-option>
                }
              </mat-select>
            </mat-form-field>
          } @else {
            <div class="radio-group" role="radiogroup" [attr.aria-label]="titleFor(question)">
              @for (option of question.options; track option.value) {
                <label
                  class="radio-option"
                  [class.is-active]="answerValue === option.value"
                >
                  <input
                    type="radio"
                    class="radio-option__input"
                    [name]="'q_' + question.id"
                    [value]="option.value"
                    [checked]="answerValue === option.value"
                    (change)="setAnswer(option.value)"
                  />
                  <span class="radio-option__dot"></span>
                  <span class="radio-option__text">{{ option.text }}</span>
                </label>
              }
            </div>
          }
        } @else if (usesLengthWidth(question)) {
          <div class="lw-group">
            <mat-form-field
              appearance="outline"
              class="ci__field lw-group__field"
              subscriptSizing="dynamic"
            >
              <mat-label>{{ 'chk.answer.length' | t }}</mat-label>
              <input
                matInput
                type="text"
                inputmode="decimal"
                [value]="lengthValue"
                (input)="onLengthInput($event)"
              />
            </mat-form-field>
            <span class="lw-group__sep">×</span>
            <mat-form-field
              appearance="outline"
              class="ci__field lw-group__field"
              subscriptSizing="dynamic"
            >
              <mat-label>{{ 'chk.answer.width' | t }}</mat-label>
              <input
                matInput
                type="text"
                inputmode="decimal"
                [value]="widthValue"
                (input)="onWidthInput($event)"
              />
            </mat-form-field>
          </div>
        } @else {
          <mat-form-field
            appearance="outline"
            class="ci__field"
            subscriptSizing="dynamic"
          >
            @if (usesTextarea(question)) {
              <textarea
                matInput
                formControlName="answerValue"
                rows="3"
                [placeholder]="'chk.answer.placeholder' | t"
                (input)="onTextInput($event)"
              ></textarea>
            } @else {
              <input
                matInput
                formControlName="answerValue"
                [type]="inputType(question)"
                [placeholder]="'chk.answer.placeholder' | t"
                (input)="onTextInput($event)"
              />
            }
          </mat-form-field>
        }

        <div class="ci__photo">
          <div class="ci__photo-meta">
            <span class="ci__photo-label">{{ 'ci.photo' | t }}</span>
            @if (question.photoRequired) {
              <span class="ci__photo-hint">{{ 'ci.photoHint' | t }}</span>
            }
          </div>
          <app-image-upload
            [image]="image"
            [disabled]="uploadDisabled && !image"
            (imageChange)="onImage($event)"
            (enlarge)="enlarge.emit($event)"
          />
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .ci {
        border: 1px solid var(--ec-border);
        border-left: 4px solid #d8e2dd;
        border-radius: 14px;
        background: #fff;
        padding: 12px 13px;
        transition: border-color 0.2s ease, background 0.2s ease;
      }
      .ci--compact {
        border: none;
        border-left: none;
        border-radius: 0;
        background: transparent;
        padding: 0;
      }
      .ci--answered {
        border-left-color: var(--ec-primary);
        background: rgba(59, 130, 246, 0.08);
      }

      .ci__top {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        margin-bottom: 12px;
      }
      .ci__idx {
        flex: 0 0 auto;
        width: 24px;
        height: 24px;
        border-radius: 8px;
        background: var(--ec-accent);
        color: #fff;
        font-size: 12.5px;
        font-weight: 700;
        display: grid;
        place-items: center;
        margin-top: 1px;
      }
      .ci__head {
        min-width: 0;
      }
      .ci__title {
        margin: 0;
        font-size: 15px;
        font-weight: 600;
        line-height: 1.5;
        color: var(--ec-text);
        word-break: break-word;
      }
      .ci__desc {
        margin: 4px 0 0;
        font-size: 12.5px;
        line-height: 1.45;
        color: var(--ec-text-muted);
      }

      .ci__body {
        display: flex;
        flex-direction: column;
        gap: 12px;
      }
      .ci__field {
        width: 100%;
      }
      .ci__field ::ng-deep .mat-mdc-text-field-wrapper {
        border-radius: 15px;
        background: #fff;
      }
      .ci__field ::ng-deep .mdc-notched-outline__leading {
        border-radius: 15px 0 0 15px;
        width: 15px;
      }
      .ci__field ::ng-deep .mdc-notched-outline__trailing {
        border-radius: 0 15px 15px 0;
      }
      .ci__field ::ng-deep .mat-mdc-form-field-infix {
        min-height: 44px;
        padding-top: 10px;
        padding-bottom: 10px;
      }
      .ci__field ::ng-deep .mat-mdc-form-field-subscript-wrapper {
        display: none;
      }

      .lw-group {
        display: flex;
        align-items: center;
        gap: 8px;
      }
      .lw-group__field {
        flex: 1 1 0;
        min-width: 0;
      }
      .lw-group__sep {
        flex: 0 0 auto;
        font-size: 14px;
        font-weight: 700;
        color: var(--ec-text-muted);
      }

      .radio-group {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
      }
      .radio-option {
        position: relative;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        border: 1px solid var(--ec-border);
        background: #fff;
        min-height: 42px;
        padding: 8px 14px 8px 10px;
        border-radius: 12px;
        font-family: inherit;
        font-size: 13.5px;
        font-weight: 600;
        color: var(--ec-text-muted);
        cursor: pointer;
        transition: all 0.18s ease;
      }
      .radio-option.is-active {
        background: rgba(59, 130, 246, 0.08);
        border-color: var(--ec-primary);
        color: var(--ec-text);
        box-shadow: 0 4px 10px rgba(59, 130, 246, 0.16);
      }
      .radio-option__input {
        position: absolute;
        opacity: 0;
        width: 1px;
        height: 1px;
        margin: 0;
      }
      .radio-option__dot {
        flex: 0 0 auto;
        width: 18px;
        height: 18px;
        border-radius: 50%;
        border: 2px solid var(--ec-border);
        background: #fff;
        display: grid;
        place-items: center;
        transition: border-color 0.18s ease;
      }
      .radio-option__dot::after {
        content: '';
        width: 9px;
        height: 9px;
        border-radius: 50%;
        background: var(--ec-primary);
        transform: scale(0);
        transition: transform 0.18s ease;
      }
      .radio-option.is-active .radio-option__dot {
        border-color: var(--ec-primary);
      }
      .radio-option.is-active .radio-option__dot::after {
        transform: scale(1);
      }
      .radio-option__text {
        line-height: 1.3;
      }

      .ci__photo {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
      }
      .ci__photo-meta {
        display: flex;
        flex-direction: column;
        gap: 2px;
      }
      .ci__photo-label {
        font-size: 13px;
        font-weight: 600;
        color: var(--ec-text);
      }
      .ci__photo-hint {
        font-size: 12px;
        color: var(--ec-text-muted);
      }
    `,
  ],
})
export class ChecklistItemComponent implements OnChanges {
  private readonly cdr = inject(ChangeDetectorRef);

  @Input({ required: true }) group!: FormGroup;
  @Input({ required: true }) question!: SurveyQuestion;
  @Input() answerValue: AnswerValue = null;
  @Input() image: string | null = null;
  @Input() index = 0;
  @Input() compact = false;
  @Input() uploadDisabled = false;

  @Output() answerChange = new EventEmitter<AnswerValue>();
  @Output() imageChange = new EventEmitter<string | null>();
  @Output() enlarge = new EventEmitter<string>();

  ngOnChanges(changes: SimpleChanges): void {
    if (
      changes['question'] ||
      changes['answerValue'] ||
      changes['image'] ||
      changes['index']
    ) {
      this.cdr.markForCheck();
    }
  }

  get hasAnswer(): boolean {
    return (this.answerValue ?? '').trim().length > 0;
  }

  titleFor(question: SurveyQuestion): string {
    return question.titleHi?.trim() || question.titleEn?.trim() || '';
  }

  descriptionFor(question: SurveyQuestion): string {
    return question.descHi?.trim() || question.descEn?.trim() || '';
  }

  isChoiceQuestion(question: SurveyQuestion): boolean {
    return question.options.length > 0 && (question.ansType === 'R' || question.ansType === 'D');
  }

  usesSelect(question: SurveyQuestion): boolean {
    return question.ansType === 'D';
  }

  usesTextarea(question: SurveyQuestion): boolean {
    return question.qType === 'T';
  }

  /** Room length/width (Q_TYPE `LB`) — two decimal fields instead of one text box. */
  usesLengthWidth(question: SurveyQuestion): boolean {
    return question.qType === 'LB';
  }

  inputType(question: SurveyQuestion): string {
    return question.qType === 'N' ? 'number' : 'text';
  }

  get lengthValue(): string {
    return this.splitLengthWidth(this.answerValue).length;
  }

  get widthValue(): string {
    return this.splitLengthWidth(this.answerValue).width;
  }

  onLengthInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    const next = this.sanitizeDecimal(target.value);
    target.value = next;
    this.emitLengthWidth(next, this.widthValue);
  }

  onWidthInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    const next = this.sanitizeDecimal(target.value);
    target.value = next;
    this.emitLengthWidth(this.lengthValue, next);
  }

  private emitLengthWidth(length: string, width: string): void {
    const combined = length.trim() || width.trim() ? `${length.trim()} x ${width.trim()}` : '';
    this.setAnswer(combined);
  }

  private splitLengthWidth(value: AnswerValue): { length: string; width: string } {
    const raw = (value ?? '').trim();
    if (!raw) {
      return { length: '', width: '' };
    }
    const [length = '', width = ''] = raw.split(/\s*[x×X]\s*/);
    return { length: length.trim(), width: width.trim() };
  }

  /** Restricts free-typed input to digits + at most one dot + 2 decimal places. */
  private sanitizeDecimal(value: string): string {
    let cleaned = value.replace(/[^\d.]/g, '');
    const firstDot = cleaned.indexOf('.');
    if (firstDot >= 0) {
      cleaned =
        cleaned.slice(0, firstDot + 1) +
        cleaned.slice(firstDot + 1).replace(/\./g, '');
    }
    const [intPart, decPart] = cleaned.split('.');
    return decPart !== undefined ? `${intPart}.${decPart.slice(0, 2)}` : cleaned;
  }

  setAnswer(value: AnswerValue): void {
    const next = this.normalizeAnswerValue(value);
    this.group.get('answerValue')?.setValue(next);
    this.group.get('answerValue')?.markAsDirty();
    this.answerChange.emit(next);
  }

  onTextInput(event: Event): void {
    const target = event.target as HTMLInputElement | HTMLTextAreaElement | null;
    this.answerChange.emit((target?.value ?? '').toString());
  }

  onImage(image: string | null): void {
    this.group.get('image')?.setValue(image);
    this.group.get('image')?.markAsDirty();
    this.imageChange.emit(image);
  }

  private normalizeAnswerValue(value: AnswerValue): AnswerValue {
    const raw = (value ?? '').trim();
    return raw.length > 0 ? raw : null;
  }
}
