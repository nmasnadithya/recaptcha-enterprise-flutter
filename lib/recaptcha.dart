// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:recaptcha_enterprise_flutter/recaptcha_badge_location.dart';

import 'recaptcha_enterprise_platform_interface.dart';
import 'recaptcha_client.dart';

/// Entry point for the Recaptcha APIS
class Recaptcha {
  /// Returns a [RecaptchaClient] associated with the [siteKey] to access all
  /// reCAPTCHA APIs. It uses the fetchClient API that has built-in retries.
  /// The [badge] parameter is optional and it is used to set the badge location in web
  static Future<RecaptchaClient> fetchClient(String siteKey, {RecaptchaBadgeLocation? badge}) async {
    return RecaptchaEnterprisePlatform.instance
        .fetchClient(siteKey, badge: badge?.location)
        .then((_) {
      return RecaptchaClient();
    });
  }
}
