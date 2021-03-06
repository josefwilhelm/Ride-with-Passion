import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ride_with_passion/locator.dart';
import 'package:ride_with_passion/logger.dart';
import 'package:ride_with_passion/models/challenge.dart';
import 'package:ride_with_passion/models/route.dart';
import 'package:ride_with_passion/models/timer.dart';
import 'package:ride_with_passion/router.dart';
import 'package:ride_with_passion/services/location_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerService {
  final log = getLogger("TimerService");
  DateTime _startTime;
  Timer _timer;
  String _routeId;
  String _routeName;
  Position _endRouteChallenge;
  ChallengeRoute _challengeRoute;
  SharedPreferences _prefs;
  Challenge _challengeData;

  final _locationService = getIt<LocationService>();
  BehaviorSubject<String> _timerCounter = BehaviorSubject()..add('00:00:00');
  BehaviorSubject<bool> _running = BehaviorSubject()..add(false);

  BehaviorSubject<String> get timerCounter => _timerCounter;

  BehaviorSubject<bool> get running => _running;

  String get routeName => _routeName;

  ChallengeRoute get challengeRoute => _challengeRoute;

  TimerService() {
    startWithoutRouteId();
  }

  void startWithChallenge(ChallengeRoute challengeRoute) async {
    initValueWhenStart(challengeRoute);
    await checkTimerFromSetting();
    await saveToSetting();
    await startTheChallenge();
  }

  void startWithoutRouteId() async {
    if (!running.value) {
      ChallengeRoute challengeRouteFromSetting = await checkTimerFromSetting();
      if (challengeRouteFromSetting == null) {
        log.i('not found any key');
        return;
      } else {
        initValueWhenStart(challengeRouteFromSetting);
        await startTheChallenge();
      }
    }
  }

  initValueWhenStart(ChallengeRoute challengeRoute) {
    _challengeData = Challenge(
      userId: DateTime.now().microsecondsSinceEpoch,
      rankList: challengeRoute.rankList,
      challengeName: challengeRoute.name,
      trackId: challengeRoute.routeId,
      endCoordinates: challengeRoute.endCoordinates,
    );
    _challengeRoute = challengeRoute;
    _endRouteChallenge = Position(
        latitude: challengeRoute.endCoordinates.lat,
        longitude: challengeRoute.endCoordinates.lon);
    _routeId = challengeRoute.routeId;
    _routeName = challengeRoute.name;
  }

  Future<int> getTimerCounter() async {
    if (_startTime == null) {
      await checkTimerFromSetting();
    }
    return DateTime.now().difference(_startTime).inSeconds;
  }

  startTheChallenge() async {
    _running.add(true);
    startTimer();
    //listenWhenReachedEndLine();
  }

  //todo remove this later, save just in case client want it back
  /*
  Future<bool> isReachedEndLine() async {
    if (_endRouteChallenge == null) {
      return false;
    }
    Position position = await _locationService.getCurrentPosition();
    final initDistance =
        await _locationService.getDistance(_endRouteChallenge, position);
    return FunctionUtils.isDoubleBelow(initDistance);
  }

  listenWhenReachedEndLine() async {
    if (_endRouteChallenge == null) {
      log.i('no end route chalange');
      return;
    }
    if (await isReachedEndLine() && running.value) {
      stopFromButton();
      _challengeData.duration = Duration(seconds: await getTimerCounter());
      Get.toNamed(BikeChallengesEndRoute, arguments: _challengeData);
    }
    _locationService.getUpdateLocation((newPosition) {
      log.i(
          'position updated, current position ${newPosition.latitude} ${newPosition.longitude} end line ${_endRouteChallenge.latitude} ${_endRouteChallenge.longitude}');
      _locationService
          .getDistance(_endRouteChallenge, newPosition)
          .then((distance) async {
        await finishChallenge(distance);
      });
    });
  }*/

  Future finishChallenge() async {
    if (running.value) {
      _challengeData.duration = Duration(seconds: await getTimerCounter());
      stopFromButton();
      Get.toNamed(BikeChallengesEndRoute, arguments: _challengeData);
    }
  }

  Future<bool> isAllowedToTimerScreen(ChallengeRoute challengeRoute) async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.getString('pref_timer') != null) {
      TimerObject timerObject =
          TimerObject.fromJson(json.decode(_prefs.getString('pref_timer')));
      if (timerObject.challengeRoute.routeId == challengeRoute.routeId) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  Future<bool> isSettingTimerEmpty() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.getString('pref_timer') != null) {
      return false;
    } else {
      return true;
    }
  }

  Future<ChallengeRoute> checkTimerFromSetting() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.getString('pref_timer') != null) {
      TimerObject timerObject =
          TimerObject.fromJson(json.decode(_prefs.getString('pref_timer')));
      if (timerObject != null) {
        _startTime = timerObject.startTime;
        _timerCounter
            .add(formattedTimer(Duration(seconds: await getTimerCounter())));
      }
      return timerObject.challengeRoute;
    } else {
      log.i('timer in setting is null');
      return null;
    }
  }

  Future saveToSetting() async {
    log.i('save to setting ${_challengeRoute.name}');
    _prefs = await SharedPreferences.getInstance();
    _prefs.setString(
        'pref_timer',
        json.encode(TimerObject(
            startTime: DateTime.now(), challengeRoute: _challengeRoute)));
    _startTime = DateTime.now();
    log.i(
        'setting saved. time ${DateTime.now()} route name: ${_challengeRoute.name}');
  }

  void startTimer() async {
    if (_timer != null) return;
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      _timerTick();
    });
  }

  void _timerTick() async {
    //todo check different here instead of plus one
    _timerCounter.value =
        formattedTimer(Duration(seconds: await getTimerCounter()));
  }

  stopFromButton() async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.remove('pref_timer');
    await stopTimer();
  }

  stopTimer() async {
    if (_routeId != null) {
      _timer?.cancel();
      _timer = null;
      _running.add(false);
      _timerCounter.add('00:00:00');
    }
  }

  static String formattedTimer(Duration duration) {
    String twoDigits(int n, {int pad: 2}) {
      var str = n.toString();
      var paddingToAdd = pad - str.length;
      return (paddingToAdd > 0)
          ? "${new List.filled(paddingToAdd, '0').join('')}$str"
          : str;
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
