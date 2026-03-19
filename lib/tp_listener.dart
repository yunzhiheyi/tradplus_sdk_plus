import 'package:tradplus_sdk_plus/tradplus_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

final TPListenerManager = TPListenerCenter();
const bool _tpVerboseLoggingEnabled = false;

void _tpLog(String message) {
  if (_tpVerboseLoggingEnabled) {
    debugPrint(message);
  }
}

class TPListenerCenter {
  TPInterActiveAdListener? interActiveAdListener;
  final Map interActiveAdListenerMap = {};

  TPNativeAdListener? nativeAdListener;
  final Map nativeAdListenerMap = {};

  TPInterstitialAdListener? interstitialAdListener;
  final Map interstitialAdListenerMap = {};

  TPRewardVideoAdListener? rewardVideoAdListener;
  final Map rewardVideoAdListenerMap = {};

  TPOfferwallAdListener? offerwallAdListener;
  final Map offerwallAdListenerMap = {};

  TPSplashAdListener? splashAdListener;
  final Map splashAdListenerMap = {};

  TPBannerAdListener? bannerAdListener;
  final Map bannerAdListenerMap = {};

  TPInitListener? initListener;

  TTDUID2Listener? uid2Listener;

  TPGlobalAdImpressionListener? globalAdImpressionListener;

  TPListenerCenter() {
    _tpLog('[tradplus][listener_center] init');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      TradplusSdk.eventChannel.receiveBroadcastStream().listen((event) {
        // Android 插件实现了 EventChannel，iOS 目前仅走 MethodChannel。
        String method = event["method"];
        Map data = event["data"];
        _tpLog('[tradplus][event] stream method=$method');
        tpMethodCall(method, data);
      }, onError: (Object error, StackTrace stackTrace) {
        debugPrint('[tradplus][event] stream error=$error\n$stackTrace');
      });
    } else {
      _tpLog('[tradplus][event] stream disabled on platform=$defaultTargetPlatform');
    }
    TradplusSdk.channel.setMethodCallHandler((MethodCall call) async {
      String method = call.method;
      _tpLog('[tradplus][event] methodChannel method=$method');
      tpMethodCall(method, call.arguments);
    });
  }

  tpMethodCall(String method, dynamic map) {
    _tpLog('[tradplus][dispatch] method=$method');
    if (method == 'tp_globalAdImpression') {
      globalAdImpressionCallBack(method, map);
    } else if (method.startsWith("uid2_")) {
      uid2CallBack(method, map);
    } else if (method.startsWith("tp_")) {
      //SDK相关
      tpCallBack(method, map);
    } else if (method.startsWith("native_")) {
      nativeCallBack(method, map);
    } else if (method.startsWith("interstitial_")) {
      interstitialCallBack(method, map);
    } else if (method.startsWith("rewardVideo_")) {
      rewardVideoCallBack(method, map);
    } else if (method.startsWith("banner_")) {
      bannerCallBack(method, map);
    } else if (method.startsWith("splash_")) {
      splashCallBack(method, map);
    } else if (method.startsWith("offerwall_")) {
      offerwallCallBack(method, map);
    } else if (method.startsWith("interactive_")) {
      interActiveCallBack(method, map);
    } else {
      debugPrint("[tradplus][dispatch] unknown method=$method");
    }
  }

  globalAdImpressionCallBack(String method, dynamic arguments) {
    if (globalAdImpressionListener == null) {
      debugPrint("[tradplus][global] listener not set");
      return;
    }
    TPSDKManager.globalAdImpressionCallback(
        globalAdImpressionListener!, method, arguments);
  }

  tpCallBack(String method, dynamic arguments) {
    if (initListener == null) {
      debugPrint("[tradplus][init] listener not set");
      return;
    }
    TPSDKManager.callback(initListener!, method, arguments);
  }

  uid2CallBack(String method, dynamic arguments) {
    if (uid2Listener == null) {
      debugPrint("[tradplus][uid2] listener not set");
      return;
    }
    ttdUID2Manager.callback(uid2Listener!, method, arguments);
  }

  offerwallCallBack(String method, dynamic arguments) {
    String adUnitId = "";
    if (arguments.containsKey("adUnitID")) {
      adUnitId = arguments["adUnitID"];
    }
    TPOfferwallAdListener? callBackListener;
    if (adUnitId.isNotEmpty && offerwallAdListenerMap.containsKey(adUnitId)) {
      callBackListener = offerwallAdListenerMap[adUnitId];
    } else {
      callBackListener = offerwallAdListener;
    }
    if (callBackListener == null) {
      debugPrint("[tradplus][offerwall] no listener for adUnitId=$adUnitId method=$method");
      return;
    }
    TPOfferWallManager.callback(callBackListener, adUnitId, method, arguments);
  }

  splashCallBack(String method, dynamic arguments) {
    String adUnitId = "";
    if (arguments.containsKey("adUnitID")) {
      adUnitId = arguments["adUnitID"];
    }
    TPSplashAdListener? callBackListener;
    if (adUnitId.isNotEmpty && splashAdListenerMap.containsKey(adUnitId)) {
      callBackListener = splashAdListenerMap[adUnitId];
    } else {
      callBackListener = splashAdListener;
    }
    if (callBackListener == null) {
      debugPrint("[tradplus][splash] no listener for adUnitId=$adUnitId method=$method");
      return;
    }
    _tpLog("[tradplus][splash] dispatch to listener adUnitId=$adUnitId method=$method");
    TPSplashManager.callback(callBackListener, adUnitId, method, arguments);
  }

  bannerCallBack(String method, dynamic arguments) {
    String adUnitId = "";
    if (arguments.containsKey("adUnitID")) {
      adUnitId = arguments["adUnitID"];
    }
    TPBannerAdListener? callBackListener;
    if (adUnitId.isNotEmpty && bannerAdListenerMap.containsKey(adUnitId)) {
      callBackListener = bannerAdListenerMap[adUnitId];
    } else {
      callBackListener = bannerAdListener;
    }
    if (callBackListener == null) {
      debugPrint("[tradplus][banner] no listener for adUnitId=$adUnitId method=$method");
      return;
    }
    TPBannerManager.callback(callBackListener, adUnitId, method, arguments);
  }

  interActiveCallBack(String method, dynamic arguments) {
    String adUnitId = "";
    if (arguments.containsKey("adUnitID")) {
      adUnitId = arguments["adUnitID"];
    }
    TPInterActiveAdListener? callBackListener;
    if (adUnitId.isNotEmpty && interActiveAdListenerMap.containsKey(adUnitId)) {
      callBackListener = interActiveAdListenerMap[adUnitId];
    } else {
      callBackListener = interActiveAdListener;
    }
    if (callBackListener == null) {
      debugPrint("[tradplus][interactive] no listener for adUnitId=$adUnitId method=$method");
      return;
    }
    TPInteractiveManager.callback(
        callBackListener, adUnitId, method, arguments);
  }

  rewardVideoCallBack(String method, dynamic arguments) {
    String adUnitId = "";
    if (arguments.containsKey("adUnitID")) {
      adUnitId = arguments["adUnitID"];
    }
    TPRewardVideoAdListener? callBackListener;
    if (adUnitId.isNotEmpty && rewardVideoAdListenerMap.containsKey(adUnitId)) {
      callBackListener = rewardVideoAdListenerMap[adUnitId];
    } else {
      callBackListener = rewardVideoAdListener;
    }
    if (callBackListener == null) {
      debugPrint("[tradplus][reward] no listener for adUnitId=$adUnitId method=$method");
      return;
    }
    TPRewardVideoManager.callback(
        callBackListener, adUnitId, method, arguments);
  }

  interstitialCallBack(String method, dynamic arguments) {
    String adUnitId = "";
    if (arguments.containsKey("adUnitID")) {
      adUnitId = arguments["adUnitID"];
    }
    TPInterstitialAdListener? callBackListener;
    if (adUnitId.isNotEmpty &&
        interstitialAdListenerMap.containsKey(adUnitId)) {
      callBackListener = interstitialAdListenerMap[adUnitId];
    } else {
      callBackListener = interstitialAdListener;
    }
    if (callBackListener == null) {
      debugPrint("[tradplus][interstitial] no listener for adUnitId=$adUnitId method=$method");
      return;
    }
    TPInterstitialManager.callback(
        callBackListener, adUnitId, method, arguments);
  }

  nativeCallBack(String method, dynamic arguments) {
    String adUnitId = "";
    if (arguments.containsKey("adUnitID")) {
      adUnitId = arguments["adUnitID"];
    }
    TPNativeAdListener? callBackListener;
    if (adUnitId.isNotEmpty && nativeAdListenerMap.containsKey(adUnitId)) {
      callBackListener = nativeAdListenerMap[adUnitId];
    } else {
      callBackListener = nativeAdListener;
    }
    if (callBackListener == null) {
      debugPrint("[tradplus][native] no listener for adUnitId=$adUnitId method=$method");
      return;
    }
    TPNativeManager.callback(callBackListener, adUnitId, method, arguments);
  }
}
