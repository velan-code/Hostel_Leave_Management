import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isSoundEnabled = true;
  bool _isInitialized = false;

  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('sound_effects_enabled') ?? true;
      _isInitialized = true;
      // Lower volume slightly so sound effects are pleasant and non-intrusive
      await _player.setVolume(0.5);
    } catch (e) {
      debugPrint('Error initializing SoundService: $e');
    }
  }

  Future<void> toggleSound(bool enabled) async {
    _isSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_effects_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving sound preference: $e');
    }
  }

  Future<void> playTap() async {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);

    if (!_isSoundEnabled) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(base64Decode(_tapB64)));
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  Future<void> playSuccess() async {
    HapticFeedback.mediumImpact();
    if (!_isSoundEnabled) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(base64Decode(_successB64)));
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  Future<void> playDecline() async {
    HapticFeedback.heavyImpact();
    if (!_isSoundEnabled) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(base64Decode(_declineB64)));
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  Future<void> playNotification() async {
    HapticFeedback.selectionClick();
    if (!_isSoundEnabled) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(base64Decode(_notifB64)));
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  // Base64 Audio PCM Data
  static const String _tapB64 =
      'RIFFRAAAAFdAVkVmbXQAEAAAAAEAAQAEsAAAAAEAAAEAAABkYXRhBgAAAPn/7v/f/9L/xv+8/7X/sv+w/7D/sf+3/73/xP/L/9L/2f/g/+b/6//w//X/+P/7//7/AAACAAcADQAWAB8AKAAyADwARgBQAFAATABFAEQARABFAEgATgBWAFAARAA4ACsAHgATAAkAAAAAAPn/6f/X/8P/rv+Z/4D/cf9p/2n/bv90/3r/gP+H/47/lP+a/57/oP+g/6H/o/+k/6X/pv+n/6f/qP+p/6r/qv+r/6z/rP+t/63/rP+s/6r/qP+l/6H/nP+V/4v/gP93/2r/Y/9f/1//YP9l/2r/c/97/4L/iv+R/5j/nv+i/6X/qP+q/6v/rf+u/67/rv+u/67/rv+u/67/rv+u/67/rv+u/63/q/+q/6f/pP+g/5v/lP+K/4D/df9q/2D/V/9R/07/Tv9R/1X/W/9h/2n/cf94/37/hA+KD44PkQ+UD5YPlw+ZD5oPmw+cD5wPnA+bD5sPlw+VD5IPjg+ID4MP+wP1A/AD6wPmA+AD2wPTA8kDwAOxA6UDjgN+A3ADZwNeA1QDSAE+AzQCLQIkAh4CGQIVAhMCEQIQAhACEQIRAhMCEwIUAhQCEwIRAg8CDAIHAAMAAAD6//P/6f/e/9P/xg++D7MPqg+hD5oPkw+MD4YPfA9zD2UPYA9aD1EPRA8+DzgPNA8yDzAPMA8wDzAPMQ8xDzAALwAuACoAJgAgABsAFQARAAwABgAAAAAA9v/m/9n/yv+5/6n/mf+F/3H/Yf9V/0j/PP8wACUAIAAYAAsAAAAAAPj/7v/k/9r/0P/F/7v/s/+r/6T/nf+Y/5L/jP+H/4L/ff94/3T/cf9u/2v/af9n/2X/Y/9j/2L/Yf9h/2D/YP9f/17/Xv9d/13/XP9c/1z/XP9d/13/Xv9e/1//YAD4/+/v8v/3//z/AAAAAQACAAQABwAKAA4AEgAWABoAHQAhACQAKAAqAC0ALwAxADMAMwA0ADUANgA2ADYANwA3ADcANgA2ADYANQA0ADMAMwAxAC8ALQApACYAIgAeABoAFQARAA0ACAACAAAA9P/m/9n/y//A/7X/qv+e/5T/iP99/3L/Z/9d/1T/S/9CAAA=';

  static const String _successB64 =
      'RIFF4jUAAFdAVkVmbXQAEAAAAAEAAQAEsAAAAAEAAAEAAABkYXRh0jUAAID8f/p/+f/3//H/6//j/9z/1P/L/8P/u/+y/6r/ov+b/5P/iv+B/3n/bv9l/1z/U/9K/0H/N/8tACMAFgAKAAAAAAD3/+v/3v/R/8X/u/+s/6D/lP+G/3j/awBgAFUASQA8AC8AIAAWAAkAAAAAAPf/6P/Z/8j/t/+m/5b/hgB2AGcAVgBGADkAKgAdABIAAwD4/+r/2//M/7z/r/+d/4n/e/9pAFgARwA5ACsAHAAPAPn/6P/W/8b/tf+k/5L/fwBsAFkASAA6ACoAHAAMAPf/6v/Z/8r/uv+p/5f/hP9yAF8ATwA9AC8AHwATAAMA+P/r/9z/y//B/7L/o/+S/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+V/4P/cgBfAE8APQAuAB8AEwADAAD5/+v/3P/L/8H/sv+i/5L/fwBsAFgARwA6ACoAGwANAPf/6f/Y/8j/uf+o/5X/g/9yAF8ATwA9AC4AHwATAPj/7P/d/8z/wv+z/6P/k/9/AGwAWABHADoAKgAbAA0A9//p/9j/yP+5/6j/lP+D/3IAXwBPAD0ALgAfABMA+P/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA+f/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA+f/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA+f/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA+f/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA+f/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA+f/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA+f/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA';

  static const String _declineB64 =
      'RIFF4jUAAFdAVkVmbXQAEAAAAAEAAQAEsAAAAAEAAAEAAABkYXRh0jUAAID8f/p/+f/3//H/6//j/9z/1P/L/8P/u/+y/6r/ov+b/5P/iv+B/3n/bv9l/1z/U/9K/0H/N/8tACMAFgAKAAAAAAD3/+v/3v/R/8X/u/+s/6D/lP+G/3j/awBgAFUASQA8AC8AIAAWAAkAAAAAAPf/6P/Z/8j/t/+m/5b/hgB2AGcAVgBGADkAKgAdABIAAwD4/+r/2//M/7z/r/+d/4n/e/9pAFgARwA5ACsAHAAPAPn/6P/W/8b/tf+k/5L/fwBsAFkASAA6ACoAHAAMAPf/6v/Z/8r/uv+p/5f/hP9yAF8ATwA9AC8AHwATAAMA+P/r/9z/y//B/7L/o/+S/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+V/4P/cgBfAE8APQAuAB8AEwADAAD5/+v/3P/L/8H/sv+i/5L/fwBsAFkARwA6ACoAGwANAPf/6f/Y/8j/uf+o/5X/g/9yAF8ATwA9AC4AHwATAPj/7P/d/8z/wv+z/6P/k/9/AGwAWABHADoAKgAbAA0A9//p/9j/yP+5/6j/lP+D/3IAXwBPAD0ALgAfABMA+P/s/93/zP/C/7P/o/+T/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+U/4P/cgBfAE8APQAuAB8AEwAA';

  static const String _notifB64 =
      'RIFF2C4AAFdAVkVmbXQAEAAAAAEAAQAEsAAAAAEAAAEAAABkYXRh0C4AAID8f/p/+f/3//H/6//j/9z/1P/L/8P/u/+y/6r/ov+b/5P/iv+B/3n/bv9l/1z/U/9K/0H/N/8tACMAFgAKAAAAAAD3/+v/3v/R/8X/u/+s/6D/lP+G/3j/awBgAFUASQA8AC8AIAAWAAkAAAAAAPf/6P/Z/8j/t/+m/5b/hgB2AGcAVgBGADkAKgAdABIAAwD4/+r/2//M/7z/r/+d/4n/e/9pAFgARwA5ACsAHAAPAPn/6P/W/8b/tf+k/5L/fwBsAFkASAA6ACoAHAAMAPf/6v/Z/8r/uv+p/5f/hP9yAF8ATwA9AC8AHwATAAMA+P/r/9z/y//B/7L/o/+S/38AbABYAEcAOgAqABsADQD3/+n/2P/I/7n/qP+V/4P/cgBfAE8APQAuAB8AEwADAAD5/+v/3P/L/8H/sv+i/5L/fwBsAFkARwA6ACoAGwANAPf/6f/Y/8j/uf+o/5X/g/9yAF8ATwA9AC4AHwATAPj/7P/d/8z/wv+z/6P/k/9/AGwAWABHADoAKgAbAA0A9//p/9j/yP+5/6j/lP+D/3IAXwBPAD0ALgAfABM=';
}
