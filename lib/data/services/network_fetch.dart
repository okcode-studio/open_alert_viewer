/*
 * SPDX-FileCopyrightText: 2024 Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../../background/background.dart';
import '../repositories/settings_repository.dart';

mixin NetworkFetch {
  Future<http.Response> networkFetch(
      String baseURL, String username, String password, String restOfURL,
      {String? postBody,
      bool? authOverride,
      Map<String, String>? headers,
      int? maxTimeout}) async {
    Map<String, String> collectedHeaders = {
      "User-Agent": "open_alert_viewer/${SettingsRepo.appVersion}"
    };
    collectedHeaders.addAll(headers ?? {});
    if ((username != "" || password != "") && !(authOverride ?? false)) {
      var basicAuth =
          "Basic ${base64.encode(utf8.encode("$username:$password"))}";
      collectedHeaders["authorization"] = basicAuth;
    }
    String url = generateURL(baseURL, restOfURL);
    if (RegExp(r"^http://").hasMatch(url) &&
        !RegExp(r"^http://localhost(:[0-9]+)?(/.*)?$").hasMatch(url)) {
      return http.Response("426 HTTPS required", 426,
          reasonPhrase: "HTTPS Required");
    }
    Uri? parsedURI;
    Future<Response> query;
    try {
      parsedURI = Uri.parse(url);
    } catch (e) {
      parsedURI = null;
    }
    if (parsedURI == null || parsedURI.host == "") {
      return http.Response("400 Bad Request", 400, reasonPhrase: "Bad Request");
    }
    if (postBody == null) {
      query = http.get(parsedURI, headers: collectedHeaders);
    } else {
      query = http.post(parsedURI, headers: collectedHeaders, body: postBody);
    }
    var timeout = BackgroundChannel.settings!.syncTimeout;
    if (maxTimeout != null) {
      timeout = (timeout > maxTimeout) ? maxTimeout : timeout;
    }
    var response =
        await query.timeout(Duration(seconds: timeout), onTimeout: () {
      return http.Response("408 Client Timeout", 408,
          reasonPhrase: "Client Timeout");
    });
    return response;
  }

  String generateURL(String baseURL, String restOfURL) {
    String prefix;
    if (RegExp(r"^https?://").hasMatch(baseURL)) {
      prefix = "";
    } else if (RegExp(r"^localhost(:[0-9]*)?(/.*)?$").hasMatch(baseURL)) {
      prefix = "http://";
    } else {
      prefix = "https://";
    }
    return prefix + baseURL + restOfURL;
  }
}