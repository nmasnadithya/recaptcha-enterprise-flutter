import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_enterprise_platform_interface.dart';
import 'package:web/web.dart' as web;

@JS('grecaptcha.enterprise')
external GrecaptchaEnterprise get grecaptchaEnterprise;

extension type GrecaptchaEnterprise._(JSObject _) implements JSObject {
  external JSVoid ready(JSFunction callback);

  external JSPromise<JSString> execute(JSString siteKey, Options options);
}

extension type Options._(JSObject _) implements JSObject {
  external factory Options({JSString action});

  external JSString get action;
}

class RecaptchaEnterpriseWeb extends RecaptchaEnterprisePlatform {
  static String? _recaptchaKey;

  /// Constructs a RecaptchaEnterpriseWeb.
  RecaptchaEnterpriseWeb();

  static void registerWith(Registrar registrar) {
    RecaptchaEnterprisePlatform.instance = RecaptchaEnterpriseWeb();
  }

  @override
  Future<bool> initClient(String siteKey, {double? timeout}) async {
    var future = _maybeLoadLibrary(siteKey);
    try {
      if (timeout == null) {
        await future;
      } else {
        await future.timeout(Duration(milliseconds: timeout.toInt()));
      }
      await _waitForRecaptchaReady(
          timeout == null ? null : Duration(milliseconds: timeout.toInt()));
    } catch (e) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> fetchClient(String siteKey, {String? badge}) async {
    try {
      await _maybeLoadLibrary(siteKey, badge: badge);
      await _waitForRecaptchaReady(null);
    } catch (e) {
      return false;
    }
    return true;
  }

  @override
  Future<String> execute(String action, {double? timeout}) async {
    final completer = Completer<String>();
    try {
      final result = grecaptchaEnterprise
          .execute(_recaptchaKey!.toJS, Options(action: action.toJS))
          .toDart;
      final value = timeout != null
          ? await result.timeout(Duration(milliseconds: timeout.toInt()))
          : await result;
      completer.complete(value.toDart);
    } catch (e) {
      completer.completeError(e);
    }
    return completer.future;
  }

  static Future<void> _waitForRecaptchaReady(Duration? delay) async {
    if (delay != null) await Future.delayed(delay);
    while (true) {
      final completer = Completer<bool>();
      grecaptchaEnterprise.ready(() {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }.toJS);
      if (delay != null) {
        final isDone = await completer.future.timeout(
          delay,
          onTimeout: () => false,
        );
        if (isDone) return;
      } else {
        return;
      }
    }
  }

  static Future<void> _maybeLoadLibrary(String siteKey, {String? badge}) async {
    final completer = Completer();
    const scriptId = 'recaptcha_enterprise_script';
    final scriptUrl =
        'https://www.google.com/recaptcha/enterprise.js?render=$siteKey${badge != null ? '&badge=$badge' : ''}';

    if (web.document.querySelector('script#$scriptId') != null) {
      return;
    }
    _recaptchaKey = siteKey;

    web.HTMLScriptElement script = web.HTMLScriptElement()
      ..async = true
      ..id = scriptId
      ..src = scriptUrl
      ..onerror = (JSAny _) {
        if (!completer.isCompleted) {
          completer
              .completeError(Exception('Failed to load reCAPTCHA script.'));
        }
      }.toJS
      ..onload = (JSAny _) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }.toJS;

    if (web.document.head != null) {
      web.document.head!.appendChild(script);
    } else {
      web.document.appendChild(script);
    }
    return completer.future;
  }
}
