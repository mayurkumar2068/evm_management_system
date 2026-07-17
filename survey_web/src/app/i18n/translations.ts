export type Lang = 'hi' | 'en';

/**
 * Runtime translation dictionary. The active language is driven by the `lang`
 * query parameter passed by the Flutter WebView (`?lang=hi|en`).
 *
 * NOTE: location option names and checklist question titles are server-driven
 * (the API already returns Hindi/English based on `lang`), so they are not here.
 */
export const TRANSLATIONS: Record<Lang, Record<string, string>> = {
  hi: {
    // location-selection
    'loc.hero.title': 'मतदान केंद्र चयन',
    'loc.hero.sub': 'क्षेत्र चुनें और स्थान का विवरण भरें',
    'loc.areaType': 'क्षेत्र का प्रकार',
    'area.urban': 'नगरीय',
    'area.rural': 'ग्रामीण',
    'loc.note.afterSelect': 'सही स्थान चयन के बाद ही सर्वे चेकलिस्ट उपलब्ध होगी।',
    'loc.note.lockedArea': 'लॉगिन के अनुसार क्षेत्र तय है — केवल उसी प्रकार के स्थान चुनें।',
    'loc.section.location': 'स्थान का चयन',
    'loc.note.enableNext': 'सभी स्तर चुनने के बाद ही "आगे बढ़ें" बटन सक्रिय होगा।',
    'loc.next': 'आगे बढ़ें',
    'loc.validation.selectAll': 'कृपया सभी विकल्प चुनें।',
    'loc.row.areaType': 'क्षेत्र प्रकार',

    // cascade levels
    'level.district': 'जिला',
    'level.block': 'जनपद',
    'level.panchayat': 'ग्राम पंचायत',
    'level.booth': 'मतदान केंद्र',
    'level.bodyType': 'निकाय का प्रकार',
    'level.body': 'निकाय का नाम',
    'cascade.placeholder': '{label} चुनें',
    'cascade.loadError': 'डेटा लोड नहीं हो पाया। API चालू है?',

    // survey-checklist
    'chk.hero.title': 'मतदान केंद्र चेकलिस्ट',
    'chk.hero.sub': 'हर बिंदु जाँचें व आवश्यक फ़ोटो जोड़ें',
    'chk.section.location': 'चयनित स्थान',
    'chk.section.checklist': 'सर्वे चेकलिस्ट',
    'chk.loading': 'चेकलिस्ट लोड हो रही है…',
    'chk.progress': 'प्रश्न {current} / {total}',
    'chk.previous': 'पीछे',
    'chk.next': 'आगे बढ़ें',
    'chk.remark.label': 'टिप्पणी',
    'chk.remark.placeholder': 'यदि कोई विशेष टिप्पणी हो तो यहाँ लिखें…',
    'chk.empty': 'कोई प्रश्न उपलब्ध नहीं है।',
    'chk.validation.answerRequired': 'कृपया हाँ या नहीं चुनें।',
    'chk.validation.photoRequired': 'हाँ चुनने पर फ़ोटो आवश्यक है।',
    'chk.validation.locationMissing': 'मतदान केंद्र चयनित नहीं है।',
    'chk.toast.saveFail': 'उत्तर सहेजा नहीं जा सका। पुनः प्रयास करें।',
    'chk.uploads.head': 'अपलोड की गई फ़ोटो (अधिकतम: {max})',
    'chk.addMore': 'और जोड़ें',
    'chk.coords': 'लोकेशन निर्देशांक',
    'chk.feedback.label': 'अन्य टिप्पणी',
    'chk.feedback.placeholder': 'कोई अन्य जानकारी या सुझाव यहाँ लिखें… (वैकल्पिक)',
    'chk.footer.pending': '{n} प्रश्न शेष — हर प्रश्न का उत्तर व फ़ोटो आवश्यक है',
    'chk.submit': 'जानकारी भेज दें',
    'chk.confirm.title': 'जानकारी भेजें?',
    'chk.confirm.body':
      'क्या आप सर्वे की जानकारी जमा करना चाहते हैं? जमा करने के बाद बदलाव संभव नहीं होगा।',
    'chk.confirm.cancel': 'रद्द करें',
    'chk.confirm.ok': 'हाँ, भेजें',
    'chk.toast.loadFail': 'चेकलिस्ट लोड नहीं हो सकी।',
    'chk.toast.authFail': 'सत्र सत्यापित नहीं हो सका। कृपया पुनः लॉगिन करें।',
    'chk.toast.submitOk': 'सर्वे जमा हो गया।',
    'chk.toast.submitOffline':
      'सर्वे स्थानीय रूप से सहेजा गया। इंटरनेट उपलब्ध होते ही स्वतः सिंक हो जाएगा।',
    'chk.toast.submitFail': 'जमा करने में त्रुटि। पुनः प्रयास करें।',

    // checklist-item
    'ci.yesno.aria': 'हाँ या नहीं',
    'ci.yes': 'हाँ',
    'ci.no': 'नहीं',
    'ci.photo': 'फ़ोटो',
    'ci.photoHint': '* हाँ चुनने पर फ़ोटो अनिवार्य है',

    // coordinates-card
    'coord.loading': 'लाइव लोकेशन प्राप्त हो रही है…',
    'coord.live': 'लाइव लोकेशन प्राप्त',
    'coord.unavailable': 'लोकेशन उपलब्ध नहीं',
    'coord.lat': 'अक्षांश',
    'coord.lng': 'देशांतर',
    'coord.permNote': 'लोकेशन की अनुमति दें और पुनः प्रयास करें।',
    'coord.source': 'स्रोत: GPS (उच्च सटीकता)',
    'coord.retry': 'फिर से प्राप्त करें',

  // booth map
    'map.boothTitle': 'मतदान केंद्र का स्थान',
    'map.boothChip': 'मतदान केंद्र',
    'map.navigate': 'मतदान केंद्र पर जाएँ',

    // image-upload
    'img.add': 'फ़ोटो जोड़ें',
    'img.camera': 'कैमरा',
    'img.gallery': 'गैलरी',

    // common
    'common.remove': 'हटाएँ',
    'common.close': 'बंद करें',

    // geolocation errors (by GeolocationError.kind)
    'geo.unsupported': 'इस डिवाइस पर लोकेशन उपलब्ध नहीं है।',
    'geo.permission-denied': 'लोकेशन की अनुमति अस्वीकृत कर दी गई है।',
    'geo.unavailable': 'लोकेशन प्राप्त नहीं हो सकी।',
    'geo.timeout': 'लोकेशन प्राप्त करने में समय अधिक लग रहा है।',
  },

  en: {
    'loc.hero.title': 'Polling Station Selection',
    'loc.hero.sub': 'Choose the area and fill in the location details',
    'loc.areaType': 'Area Type',
    'area.urban': 'Urban',
    'area.rural': 'Rural',
    'loc.note.afterSelect':
      'The survey checklist is available only after a valid location is selected.',
    'loc.note.lockedArea':
      'Area type is fixed from login — only that location cascade is shown.',
    'loc.section.location': 'Location Selection',
    'loc.note.enableNext':
      'The "Continue" button activates only after all levels are selected.',
    'loc.next': 'Continue',
    'loc.validation.selectAll': 'Please select all options.',
    'loc.row.areaType': 'Area Type',

    'level.district': 'District',
    'level.block': 'Janpad (Block)',
    'level.panchayat': 'Gram Panchayat',
    'level.booth': 'Polling Station',
    'level.bodyType': 'Body Type',
    'level.body': 'Body Name',
    'cascade.placeholder': 'Select {label}',
    'cascade.loadError': 'Could not load data. Is the API running?',

    'chk.hero.title': 'Polling Station Checklist',
    'chk.hero.sub': 'Check each point and add the required photo',
    'chk.section.location': 'Selected Location',
    'chk.section.checklist': 'Survey Checklist',
    'chk.loading': 'Loading checklist…',
    'chk.progress': 'Question {current} of {total}',
    'chk.previous': 'Previous',
    'chk.next': 'Next',
    'chk.remark.label': 'Remark (optional)',
    'chk.remark.placeholder': 'Write any additional remark here…',
    'chk.empty': 'No questions available.',
    'chk.validation.answerRequired': 'Please select Yes or No.',
    'chk.validation.photoRequired': 'A photo is required when you select Yes.',
    'chk.validation.locationMissing': 'Polling station is not selected.',
    'chk.toast.saveFail': 'Could not save the answer. Please try again.',
    'chk.uploads.head': 'Uploaded photos (max: {max})',
    'chk.addMore': 'Add more',
    'chk.coords': 'Location Coordinates',
    'chk.feedback.label': 'Other Remarks',
    'chk.feedback.placeholder': 'Write any other info or suggestion here… (optional)',
    'chk.footer.pending': '{n} question(s) left — each needs an answer and a photo',
    'chk.submit': 'Submit Information',
    'chk.confirm.title': 'Submit information?',
    'chk.confirm.body':
      'Do you want to submit the survey information? Changes will not be possible after submission.',
    'chk.confirm.cancel': 'Cancel',
    'chk.confirm.ok': 'Yes, submit',
    'chk.toast.loadFail': 'Could not load the checklist.',
    'chk.toast.authFail': 'Could not verify session. Please log in again.',
    'chk.toast.submitOk': 'Survey submitted.',
    'chk.toast.submitOffline':
      'Survey saved locally. It will sync automatically when internet is available.',
    'chk.toast.submitFail': 'Submission failed. Please try again.',

    'ci.yesno.aria': 'Yes or No',
    'ci.yes': 'Yes',
    'ci.no': 'No',
    'ci.photo': 'Photo',
    'ci.photoHint': '* Photo is mandatory when Yes is selected',

    'coord.loading': 'Fetching live location…',
    'coord.live': 'Live location acquired',
    'coord.unavailable': 'Location unavailable',
    'coord.lat': 'Latitude',
    'coord.lng': 'Longitude',
    'coord.permNote': 'Grant location permission and try again.',
    'coord.source': 'Source: GPS (high accuracy)',
    'coord.retry': 'Retry',

    'map.boothTitle': 'Polling booth location',
    'map.boothChip': 'Polling booth',
    'map.navigate': 'Navigate to polling booth',

    'img.add': 'Add photo',
    'img.camera': 'Camera',
    'img.gallery': 'Gallery',

    'common.remove': 'Remove',
    'common.close': 'Close',

    'geo.unsupported': 'Location is not available on this device.',
    'geo.permission-denied': 'Location permission was denied.',
    'geo.unavailable': 'Could not get the location.',
    'geo.timeout': 'Getting the location is taking too long.',
  },
};
